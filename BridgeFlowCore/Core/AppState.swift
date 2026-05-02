import AppKit
import Combine
import Foundation
import Network

public struct PeerSnapshot: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var endpoint: String
    public var status: ConnectionStatus
    public var latencyMs: Double?
    public var trusted: Bool

    public init(
        id: UUID,
        name: String,
        endpoint: String,
        status: ConnectionStatus,
        latencyMs: Double? = nil,
        trusted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.endpoint = endpoint
        self.status = status
        self.latencyMs = latencyMs
        self.trusted = trusted
    }
}

@MainActor
public final class AppState: ObservableObject {
    @Published public var isRunning = false
    @Published public var connectionStatus: ConnectionStatus = .stopped
    @Published public var activePeerID: UUID?
    @Published public var activePeerName = "Local Mac"
    @Published public var latencyMs: Double?
    @Published public var peers: [PeerSnapshot] = []
    @Published public var lastError: String?

    public let settings: SettingsStore
    public let permissions: PermissionManager
    public let logger: BridgeLogger

    private let localPeerID: UUID
    private let injector: EventInjecting
    private var pairingManager: PairingManager
    private var edgeDetector: MouseEdgeDetector
    private var eventTap: EventTapManager?
    private var server: PeerServer?
    private var client: PeerClient?
    private var discovery: PeerDiscovery?
    private var connections: [UUID: PeerConnection] = [:]
    private var peerIDsByConnectionID: [UUID: UUID] = [:]
    private var discoveredEndpoints: [UUID: NWEndpoint] = [:]

    public init(
        settings: SettingsStore? = nil,
        permissions: PermissionManager? = nil,
        logger: BridgeLogger? = nil,
        injector: EventInjecting = EventInjector()
    ) {
        let resolvedSettings = settings ?? SettingsStore()
        self.settings = resolvedSettings
        self.permissions = permissions ?? PermissionManager()
        self.logger = logger ?? BridgeLogger()
        self.injector = injector
        self.localPeerID = UserDefaults.standard.bridgeFlowLocalPeerID()
        self.pairingManager = PairingManager(codeProvider: { resolvedSettings.pairingCode })
        self.edgeDetector = MouseEdgeDetector(configuration: resolvedSettings.edgeConfiguration())
        startDiscovery()
        startServer()
    }

    public var localPeerInfo: PeerInfo {
        PeerInfo(
            id: localPeerID,
            name: Host.current().localizedName ?? "This Mac",
            hostname: Host.current().name ?? "localhost",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0",
            role: settings.defaultMode
        )
    }

    public func start() {
        guard !isRunning else {
            return
        }

        startDiscovery()
        edgeDetector = MouseEdgeDetector(configuration: settings.edgeConfiguration())
        let permissionSnapshot = permissions.refresh()

        startServer()

        if settings.defaultMode == .host || settings.defaultMode == .both {
            startEventTapIfPermitted(permissionSnapshot)
        }

        isRunning = true
        logger.info("BridgeFlow started in \(settings.defaultMode.displayName) mode")
    }

    public func stop() {
        eventTap?.stop()
        eventTap = nil

        server?.stop()
        server = nil

        client?.disconnect()
        client = nil

        for connection in connections.values {
            connection.send(.control(.releaseAllKeys))
            connection.cancel()
        }
        connections.removeAll()
        peerIDsByConnectionID.removeAll()

        injector.releaseAllKeys()
        activePeerID = nil
        activePeerName = "Local Mac"
        connectionStatus = .stopped
        isRunning = false
        peers = peers.map { peer in
            var updated = peer
            updated.status = discoveredEndpoints[peer.id] == nil ? .stopped : .available
            return updated
        }
        logger.info("BridgeFlow stopped")
    }

    public func connectToConfiguredPeer() {
        connect(host: settings.peerHost, port: UInt16(settings.peerPort))
    }

    public func connect(host: String, port: UInt16) {
        guard !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            reportError("Peer IP or hostname is required")
            return
        }

        connectionStatus = .connecting
        let client = PeerClient()
        let connection = client.connect(host: host, port: port)
        self.client = client
        configure(connection)
        connection.send(.hello(peer: localPeerInfo))
        upsertPeer(PeerSnapshot(id: connection.id, name: host, endpoint: connection.endpointDescription, status: .connecting))
        logger.info("Connecting to \(host):\(port)")
    }

    public func connect(peerID: UUID) {
        guard let endpoint = discoveredEndpoints[peerID] else {
            reportError("Discovered peer endpoint is no longer available")
            return
        }

        connectionStatus = .connecting
        markPeer(peerID, status: .connecting)

        let client = PeerClient()
        let connection = client.connect(endpoint: endpoint)
        self.client = client
        configure(connection, peerID: peerID)
        connection.send(.hello(peer: localPeerInfo))
        logger.info("Connecting to discovered peer \(endpoint)")
    }

    public func disconnect(peerID: UUID) {
        guard let connection = connections[peerID] else {
            return
        }
        connection.send(.control(.releaseAllKeys))
        connection.cancel()
        connections.removeValue(forKey: peerID)
        switchToLocal()
        markPeer(peerID, status: .stopped)
        logger.info("Disconnected peer")
    }

    public func trust(peerID: UUID) {
        pairingManager.trust(peerID: peerID)
        markPeer(peerID, trusted: true)
        logger.info("Trusted peer \(peerID.uuidString)")
    }

    public func removeTrust(peerID: UUID) {
        pairingManager.remove(peerID: peerID)
        markPeer(peerID, trusted: false)
        logger.info("Removed peer trust")
    }

    public func switchToLocal() {
        if let activePeerID, let connection = connections[activePeerID] {
            connection.send(.control(.switchToLocal))
            connection.send(.control(.releaseAllKeys))
        }
        activePeerID = nil
        activePeerName = "Local Mac"
        injector.releaseAllKeys()
        connectionStatus = isRunning ? .connected : .stopped
        logger.info("Returned control to local Mac")
    }

    private func startServer() {
        guard server == nil else {
            return
        }

        do {
            let server = PeerServer(port: UInt16(settings.port), advertisedPeerInfo: localPeerInfo)
            server.onConnection = { [weak self] connection in
                Task { @MainActor in
                    self?.configure(connection)
                    connection.send(.hello(peer: self?.localPeerInfo ?? PeerInfo(id: UUID(), name: "BridgeFlow", hostname: "localhost", appVersion: "0.1.0", role: .both)))
                    self?.logger.info("Peer connected from \(connection.endpointDescription)")
                }
            }
            server.onStateChange = { [weak self] state in
                Task { @MainActor in
                    self?.handleServerState(state)
                }
            }
            server.onError = { [weak self] error in
                Task { @MainActor in
                    self?.reportError(error.localizedDescription)
                }
            }
            try server.start()
            self.server = server
            connectionStatus = .waiting
            logger.info("Server listening on port \(settings.port)")
        } catch {
            reportError("Unable to start server: \(error.localizedDescription)")
        }
    }

    private func startDiscovery() {
        guard discovery == nil else {
            return
        }

        let discovery = PeerDiscovery()
        discovery.onPeerFound = { [weak self] peer in
            Task { @MainActor in
                self?.handleDiscovered(peer)
            }
        }
        discovery.onPeerLost = { [weak self] peerID in
            Task { @MainActor in
                self?.handleLostPeer(peerID)
            }
        }
        discovery.onStateChange = { [weak self] state in
            Task { @MainActor in
                if case .ready = state {
                    self?.logger.info("Bonjour discovery ready")
                }
            }
        }
        discovery.onError = { [weak self] error in
            Task { @MainActor in
                self?.logger.warning("Bonjour discovery failed: \(error.localizedDescription)")
            }
        }
        discovery.start()
        self.discovery = discovery
    }

    private func startEventTapIfPermitted(_ snapshot: PermissionSnapshot) {
        guard snapshot.accessibilityGranted && snapshot.inputMonitoringGranted else {
            logger.warning("Input capture permissions are missing")
            return
        }

        let tap = EventTapManager { [weak self] input, type in
            guard let self else {
                return true
            }
            return self.handleLocalInput(input, type: type)
        }

        if tap.start() {
            eventTap = tap
            logger.info("Global input capture started")
        } else {
            logger.warning("Could not create event tap; check Input Monitoring")
        }
    }

    private func handleLocalInput(_ input: BridgeInputEvent, type: CGEventType) -> Bool {
        if EventNormalizer.isCancelHotKey(input) {
            Task { @MainActor in self.switchToLocal() }
            return false
        }

        if let activePeerID, let connection = connections[activePeerID] {
            connection.send(.input(input))
            return false
        }

        guard case let .mouseMove(dx, dy, _) = input,
              let screen = NSScreen.main else {
            return true
        }

        let location = NSEvent.mouseLocation
        let action = edgeDetector.evaluateLocalCursor(
            position: location,
            delta: CGVector(dx: dx, dy: dy),
            screenSize: screen.frame.size,
            timestamp: Date().timeIntervalSince1970
        )

        if case let .switchToPeer(edge) = action, let firstPeer = peers.first(where: { $0.status == .connected || $0.status == .active }) {
            activatePeer(firstPeer.id, edge: edge)
            return false
        }

        return true
    }

    private func activatePeer(_ peerID: UUID, edge: ScreenEdge) {
        guard let connection = connections[peerID] else {
            return
        }
        activePeerID = peerID
        activePeerName = peers.first(where: { $0.id == peerID })?.name ?? "Remote Mac"
        connectionStatus = .active
        connection.send(.control(.switchToPeer(peerID)))
        markPeer(peerID, status: .active)
        logger.info("Switched to peer via \(edge.displayName.lowercased()) edge")
    }

    private func configure(_ connection: PeerConnection, peerID: UUID? = nil) {
        let snapshotID = peerID ?? connection.id
        connections[snapshotID] = connection
        if let peerID {
            peerIDsByConnectionID[connection.id] = peerID
        }
        upsertPeer(PeerSnapshot(id: snapshotID, name: peerName(for: snapshotID), endpoint: connection.endpointDescription, status: .connecting))

        connection.onMessage = { [weak self] message, connection in
            Task { @MainActor in
                self?.handle(message, from: connection)
            }
        }
        connection.onStateChange = { [weak self] state, connection in
            Task { @MainActor in
                self?.handleConnectionState(state, connection: connection)
            }
        }
        connection.onError = { [weak self] error, _ in
            Task { @MainActor in
                self?.reportError(error.localizedDescription)
            }
        }
    }

    private func handle(_ message: BridgeMessage, from connection: PeerConnection) {
        switch message {
        case let .hello(peer):
            handleHello(peer, from: connection)
        case let .input(event):
            injector.inject(event)
        case let .control(command):
            handle(command, from: connection)
        case let .state(update):
            if let activePeerId = update.activePeerId {
                activePeerID = activePeerId
            }
            latencyMs = update.latencyMs
            connectionStatus = update.connectionStatus
        case let .heartbeat(timestamp):
            latencyMs = max(0, (Date().timeIntervalSince1970 - timestamp) * 1_000)
            connection.send(.heartbeat(timestamp: Date().timeIntervalSince1970))
        case let .error(message):
            reportError(message)
        }
    }

    private func handleHello(_ peer: PeerInfo, from connection: PeerConnection) {
        let previousPeerID = peerIDsByConnectionID[connection.id] ?? connection.id
        peerIDsByConnectionID[connection.id] = peer.id
        connections.removeValue(forKey: connection.id)
        removeTemporaryPeerIfNeeded(previousPeerID, realPeerID: peer.id)
        connections[peer.id] = connection
        upsertPeer(PeerSnapshot(
            id: peer.id,
            name: peer.name,
            endpoint: connection.endpointDescription,
            status: .connected,
            trusted: pairingManager.isTrusted(peer.id)
        ))
        connectionStatus = .connected
        logger.info("Peer hello received from \(peer.name)")
    }

    private func removeTemporaryPeerIfNeeded(_ temporaryPeerID: UUID, realPeerID: UUID) {
        guard temporaryPeerID != realPeerID else {
            return
        }
        connections.removeValue(forKey: temporaryPeerID)
        discoveredEndpoints.removeValue(forKey: temporaryPeerID)
        peers.removeAll { $0.id == temporaryPeerID }
    }

    private func handle(_ command: BridgeControlCommand, from connection: PeerConnection) {
        switch command {
        case let .switchToPeer(peerID):
            activePeerID = peerID
            connectionStatus = .active
        case .switchToLocal:
            injector.releaseAllKeys()
            activePeerID = nil
            connectionStatus = .connected
        case .releaseAllKeys:
            injector.releaseAllKeys()
        case .ping:
            connection.send(.heartbeat(timestamp: Date().timeIntervalSince1970))
        case .requestState:
            connection.send(.state(BridgeStateUpdate(
                activePeerId: activePeerID,
                connectionStatus: connectionStatus,
                latencyMs: latencyMs,
                permissionsStatus: permissions.snapshot
            )))
        }
    }

    private func handleServerState(_ state: NWListener.State) {
        switch state {
        case .ready:
            connectionStatus = .waiting
        case let .failed(error):
            reportError(error.localizedDescription)
        case .cancelled:
            connectionStatus = .stopped
        default:
            break
        }
    }

    private func handleConnectionState(_ state: NWConnection.State, connection: PeerConnection) {
        let peerID = peerIDsByConnectionID[connection.id] ?? connection.id
        switch state {
        case .ready:
            connectionStatus = .connected
            markPeer(peerID, status: .connected)
            connection.send(.hello(peer: localPeerInfo))
        case let .failed(error):
            reportError(error.localizedDescription)
            markPeer(peerID, status: .error)
            injector.releaseAllKeys()
        case .cancelled:
            markPeer(peerID, status: .stopped)
            injector.releaseAllKeys()
            if activePeerID == peerID {
                switchToLocal()
            }
        case .preparing, .setup, .waiting:
            markPeer(peerID, status: .connecting)
        default:
            break
        }
    }

    private func upsertPeer(_ peer: PeerSnapshot) {
        if let index = peers.firstIndex(where: { $0.id == peer.id }) {
            peers[index] = peer
        } else {
            peers.append(peer)
        }
    }

    private func handleDiscovered(_ peer: DiscoveredPeer) {
        guard peer.id != localPeerID else {
            return
        }
        guard peer.hasStableID || peer.name != localPeerInfo.name else {
            return
        }

        discoveredEndpoints[peer.id] = peer.endpoint

        if connections[peer.id] == nil {
            upsertPeer(PeerSnapshot(
                id: peer.id,
                name: peer.name,
                endpoint: peer.endpointDescription,
                status: .available,
                trusted: pairingManager.isTrusted(peer.id)
            ))
        }
    }

    private func handleLostPeer(_ peerID: UUID) {
        discoveredEndpoints.removeValue(forKey: peerID)
        guard connections[peerID] == nil else {
            return
        }
        peers.removeAll { $0.id == peerID }
    }

    private func peerName(for peerID: UUID) -> String {
        peers.first(where: { $0.id == peerID })?.name ?? "Unknown Mac"
    }

    private func markPeer(_ peerID: UUID, status: ConnectionStatus? = nil, trusted: Bool? = nil) {
        guard let index = peers.firstIndex(where: { $0.id == peerID }) else {
            return
        }
        if let status {
            peers[index].status = status
        }
        if let trusted {
            peers[index].trusted = trusted
        }
    }

    private func reportError(_ message: String) {
        lastError = message
        connectionStatus = .error
        logger.error(message)
    }
}

private extension UserDefaults {
    func bridgeFlowLocalPeerID() -> UUID {
        let key = "bridgeflow.localPeerID"
        if let value = string(forKey: key), let id = UUID(uuidString: value) {
            return id
        }
        let id = UUID()
        set(id.uuidString, forKey: key)
        return id
    }
}

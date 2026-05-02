import Foundation
import Network

public struct DiscoveredPeer: Identifiable {
    public let id: UUID
    public let name: String
    public let hostname: String
    public let appVersion: String
    public let role: AppMode
    public let endpoint: NWEndpoint
    public let endpointDescription: String
    public let hasStableID: Bool

    public init?(
        endpoint: NWEndpoint,
        txtRecord: NWTXTRecord
    ) {
        let values = txtRecord.dictionary
        let fallbackName = Self.serviceName(from: endpoint)
        let stableID = values["id"].flatMap(UUID.init(uuidString:))

        self.id = stableID ?? Self.fallbackID(for: endpoint)
        self.name = values["name"] ?? fallbackName
        self.hostname = values["hostname"] ?? ""
        self.appVersion = values["version"] ?? "unknown"
        self.role = AppMode(rawValue: values["role"] ?? "") ?? .both
        self.endpoint = endpoint
        self.endpointDescription = String(describing: endpoint)
        self.hasStableID = stableID != nil
    }

    public static func txtRecord(for peer: PeerInfo) -> NWTXTRecord {
        NWTXTRecord([
            "id": peer.id.uuidString,
            "name": peer.name,
            "hostname": peer.hostname,
            "version": peer.appVersion,
            "role": peer.role.rawValue
        ])
    }

    public static func from(_ result: NWBrowser.Result) -> DiscoveredPeer? {
        guard case let .bonjour(txtRecord) = result.metadata else {
            return nil
        }
        return DiscoveredPeer(endpoint: result.endpoint, txtRecord: txtRecord)
    }

    private static func serviceName(from endpoint: NWEndpoint) -> String {
        guard case let .service(name, _, _, _) = endpoint else {
            return String(describing: endpoint)
        }
        return name
    }

    private static func fallbackID(for endpoint: NWEndpoint) -> UUID {
        let key: String
        if case let .service(name, type, domain, _) = endpoint {
            key = "\(name).\(type).\(domain)"
        } else {
            key = String(describing: endpoint)
        }

        var hash: UInt64 = 0xcbf29ce484222325
        for byte in key.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }

        let suffix = String(format: "%012llx", hash & 0x0000FFFFFFFFFFFF)
        return UUID(uuidString: "00000000-0000-4000-8000-\(suffix)")!
    }
}

public final class PeerDiscovery {
    public static let serviceType = "_bridgeflow._tcp"

    public var onPeerFound: ((DiscoveredPeer) -> Void)?
    public var onPeerLost: ((UUID) -> Void)?
    public var onStateChange: ((NWBrowser.State) -> Void)?
    public var onError: ((Error) -> Void)?

    private let queue: DispatchQueue
    private var browser: NWBrowser?
    private var knownPeerIDsByEndpoint: [NWEndpoint: UUID] = [:]

    public private(set) var isRunning = false

    public init(queue: DispatchQueue = DispatchQueue(label: "bridgeflow.peer.discovery")) {
        self.queue = queue
    }

    public static func service(for peer: PeerInfo) -> NWListener.Service {
        NWListener.Service(
            name: peer.name,
            type: serviceType,
            domain: nil,
            txtRecord: DiscoveredPeer.txtRecord(for: peer)
        )
    }

    public func start() {
        guard !isRunning else {
            return
        }

        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true

        let browser = NWBrowser(
            for: .bonjour(type: Self.serviceType, domain: nil),
            using: parameters
        )

        browser.stateUpdateHandler = { [weak self] state in
            guard let self else {
                return
            }
            self.onStateChange?(state)
            if case let .failed(error) = state {
                self.onError?(error)
            }
        }

        browser.browseResultsChangedHandler = { [weak self] results, changes in
            guard let self else {
                return
            }
            self.handle(results: results, changes: changes)
        }

        self.browser = browser
        browser.start(queue: queue)
        isRunning = true
    }

    public func stop() {
        browser?.cancel()
        browser = nil
        knownPeerIDsByEndpoint.removeAll()
        isRunning = false
    }

    private func handle(
        results: Set<NWBrowser.Result>,
        changes: Set<NWBrowser.Result.Change>
    ) {
        changes.forEach(handleChange)
        results.compactMap(DiscoveredPeer.from).forEach(register)
    }

    private func handleChange(_ change: NWBrowser.Result.Change) {
        guard case let .removed(result) = change else {
            return
        }

        if let peerID = knownPeerIDsByEndpoint.removeValue(forKey: result.endpoint) {
            onPeerLost?(peerID)
        }
    }

    private func register(_ peer: DiscoveredPeer) {
        knownPeerIDsByEndpoint[peer.endpoint] = peer.id
        onPeerFound?(peer)
    }
}

import Foundation

@MainActor
public final class SettingsStore: ObservableObject {
    @Published public var launchAtLogin: Bool { didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) } }
    @Published public var menuBarOnly: Bool { didSet { defaults.set(menuBarOnly, forKey: Keys.menuBarOnly) } }
    @Published public var defaultMode: AppMode { didSet { defaults.set(defaultMode.rawValue, forKey: Keys.defaultMode) } }
    @Published public var port: Int { didSet { defaults.set(port, forKey: Keys.port) } }
    @Published public var peerHost: String { didSet { defaults.set(peerHost, forKey: Keys.peerHost) } }
    @Published public var peerPort: Int { didSet { defaults.set(peerPort, forKey: Keys.peerPort) } }
    @Published public var pairingCode: String { didSet { defaults.set(pairingCode, forKey: Keys.pairingCode) } }
    @Published public var edgeDelayMs: Int { didSet { defaults.set(edgeDelayMs, forKey: Keys.edgeDelayMs) } }
    @Published public var edgeDistancePx: Double { didSet { defaults.set(edgeDistancePx, forKey: Keys.edgeDistancePx) } }
    @Published public var remotePosition: ScreenEdge { didSet { defaults.set(remotePosition.rawValue, forKey: Keys.remotePosition) } }
    @Published public var showDebugLogs: Bool { didSet { defaults.set(showDebugLogs, forKey: Keys.showDebugLogs) } }
    @Published public var startOnLaunch: Bool { didSet { defaults.set(startOnLaunch, forKey: Keys.startOnLaunch) } }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.menuBarOnly = defaults.bool(forKey: Keys.menuBarOnly)
        self.defaultMode = AppMode(rawValue: defaults.string(forKey: Keys.defaultMode) ?? "") ?? .both
        self.port = defaults.object(forKey: Keys.port) as? Int ?? 48_765
        self.peerHost = defaults.string(forKey: Keys.peerHost) ?? ""
        self.peerPort = defaults.object(forKey: Keys.peerPort) as? Int ?? 48_765
        self.pairingCode = defaults.string(forKey: Keys.pairingCode) ?? PairingManager.generateCode()
        self.edgeDelayMs = defaults.object(forKey: Keys.edgeDelayMs) as? Int ?? 250
        self.edgeDistancePx = defaults.object(forKey: Keys.edgeDistancePx) as? Double ?? 6
        self.remotePosition = ScreenEdge(rawValue: defaults.string(forKey: Keys.remotePosition) ?? "") ?? .right
        self.showDebugLogs = defaults.bool(forKey: Keys.showDebugLogs)
        self.startOnLaunch = defaults.bool(forKey: Keys.startOnLaunch)
    }

    public func edgeConfiguration() -> MouseEdgeConfiguration {
        MouseEdgeConfiguration(
            remotePosition: remotePosition,
            activationDelayMs: edgeDelayMs,
            activationDistancePx: edgeDistancePx
        )
    }

    public func regeneratePairingCode() {
        pairingCode = PairingManager.generateCode()
    }

    private enum Keys {
        static let launchAtLogin = "bridgeflow.launchAtLogin"
        static let menuBarOnly = "bridgeflow.menuBarOnly"
        static let defaultMode = "bridgeflow.defaultMode"
        static let port = "bridgeflow.port"
        static let peerHost = "bridgeflow.peerHost"
        static let peerPort = "bridgeflow.peerPort"
        static let pairingCode = "bridgeflow.pairingCode"
        static let edgeDelayMs = "bridgeflow.edgeDelayMs"
        static let edgeDistancePx = "bridgeflow.edgeDistancePx"
        static let remotePosition = "bridgeflow.remotePosition"
        static let showDebugLogs = "bridgeflow.showDebugLogs"
        static let startOnLaunch = "bridgeflow.startOnLaunch"
    }
}

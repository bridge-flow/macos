import Foundation

public enum ConnectionStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case stopped
    case waiting
    case connecting
    case connected
    case active
    case error

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .stopped:
            "Stopped"
        case .waiting:
            "Waiting"
        case .connecting:
            "Connecting"
        case .connected:
            "Connected"
        case .active:
            "Active"
        case .error:
            "Error"
        }
    }
}

public struct PermissionSnapshot: Codable, Hashable, Sendable {
    public var accessibilityGranted: Bool
    public var inputMonitoringGranted: Bool

    public init(accessibilityGranted: Bool, inputMonitoringGranted: Bool) {
        self.accessibilityGranted = accessibilityGranted
        self.inputMonitoringGranted = inputMonitoringGranted
    }
}

public struct BridgeStateUpdate: Codable, Hashable, Sendable {
    public var activePeerId: UUID?
    public var connectionStatus: ConnectionStatus
    public var latencyMs: Double?
    public var permissionsStatus: PermissionSnapshot

    public init(
        activePeerId: UUID?,
        connectionStatus: ConnectionStatus,
        latencyMs: Double?,
        permissionsStatus: PermissionSnapshot
    ) {
        self.activePeerId = activePeerId
        self.connectionStatus = connectionStatus
        self.latencyMs = latencyMs
        self.permissionsStatus = permissionsStatus
    }
}

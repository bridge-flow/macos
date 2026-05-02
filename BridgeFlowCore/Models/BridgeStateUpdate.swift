import Foundation

public enum ConnectionStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case stopped
    case available
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
        case .available:
            "Available"
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
    public var peripherals: [PeripheralDevice]
    public var layout: MachineLayoutSnapshot?

    private enum CodingKeys: String, CodingKey {
        case activePeerId
        case connectionStatus
        case latencyMs
        case permissionsStatus
        case peripherals
        case layout
    }

    public init(
        activePeerId: UUID?,
        connectionStatus: ConnectionStatus,
        latencyMs: Double?,
        permissionsStatus: PermissionSnapshot,
        peripherals: [PeripheralDevice] = [],
        layout: MachineLayoutSnapshot? = nil
    ) {
        self.activePeerId = activePeerId
        self.connectionStatus = connectionStatus
        self.latencyMs = latencyMs
        self.permissionsStatus = permissionsStatus
        self.peripherals = peripherals
        self.layout = layout
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activePeerId = try container.decodeIfPresent(UUID.self, forKey: .activePeerId)
        connectionStatus = try container.decode(ConnectionStatus.self, forKey: .connectionStatus)
        latencyMs = try container.decodeIfPresent(Double.self, forKey: .latencyMs)
        permissionsStatus = try container.decode(PermissionSnapshot.self, forKey: .permissionsStatus)
        peripherals = try container.decodeIfPresent([PeripheralDevice].self, forKey: .peripherals) ?? []
        layout = try container.decodeIfPresent(MachineLayoutSnapshot.self, forKey: .layout)
    }
}

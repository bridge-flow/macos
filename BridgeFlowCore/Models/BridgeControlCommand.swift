import Foundation

public enum BridgeControlCommand: Codable, Hashable, Sendable {
    case switchToPeer(UUID)
    case switchToLocal
    case releaseAllKeys
    case ping
    case requestState

    private enum CodingKeys: String, CodingKey {
        case type
        case peerID
    }

    private enum CommandType: String, Codable {
        case switchToPeer
        case switchToLocal
        case releaseAllKeys
        case ping
        case requestState
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(CommandType.self, forKey: .type) {
        case .switchToPeer:
            self = .switchToPeer(try container.decode(UUID.self, forKey: .peerID))
        case .switchToLocal:
            self = .switchToLocal
        case .releaseAllKeys:
            self = .releaseAllKeys
        case .ping:
            self = .ping
        case .requestState:
            self = .requestState
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .switchToPeer(peerID):
            try container.encode(CommandType.switchToPeer, forKey: .type)
            try container.encode(peerID, forKey: .peerID)
        case .switchToLocal:
            try container.encode(CommandType.switchToLocal, forKey: .type)
        case .releaseAllKeys:
            try container.encode(CommandType.releaseAllKeys, forKey: .type)
        case .ping:
            try container.encode(CommandType.ping, forKey: .type)
        case .requestState:
            try container.encode(CommandType.requestState, forKey: .type)
        }
    }
}

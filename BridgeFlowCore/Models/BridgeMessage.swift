import Foundation

public enum BridgeMessage: Codable, Hashable, Sendable {
    case hello(peer: PeerInfo)
    case input(BridgeInputEvent)
    case control(BridgeControlCommand)
    case state(BridgeStateUpdate)
    case heartbeat(timestamp: TimeInterval)
    case error(message: String)

    private enum CodingKeys: String, CodingKey {
        case type
        case peer
        case input
        case control
        case state
        case timestamp
        case message
    }

    private enum MessageType: String, Codable {
        case hello
        case input
        case control
        case state
        case heartbeat
        case error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(MessageType.self, forKey: .type) {
        case .hello:
            self = .hello(peer: try container.decode(PeerInfo.self, forKey: .peer))
        case .input:
            self = .input(try container.decode(BridgeInputEvent.self, forKey: .input))
        case .control:
            self = .control(try container.decode(BridgeControlCommand.self, forKey: .control))
        case .state:
            self = .state(try container.decode(BridgeStateUpdate.self, forKey: .state))
        case .heartbeat:
            self = .heartbeat(timestamp: try container.decode(TimeInterval.self, forKey: .timestamp))
        case .error:
            self = .error(message: try container.decode(String.self, forKey: .message))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .hello(peer):
            try container.encode(MessageType.hello, forKey: .type)
            try container.encode(peer, forKey: .peer)
        case let .input(input):
            try container.encode(MessageType.input, forKey: .type)
            try container.encode(input, forKey: .input)
        case let .control(control):
            try container.encode(MessageType.control, forKey: .type)
            try container.encode(control, forKey: .control)
        case let .state(state):
            try container.encode(MessageType.state, forKey: .type)
            try container.encode(state, forKey: .state)
        case let .heartbeat(timestamp):
            try container.encode(MessageType.heartbeat, forKey: .type)
            try container.encode(timestamp, forKey: .timestamp)
        case let .error(message):
            try container.encode(MessageType.error, forKey: .type)
            try container.encode(message, forKey: .message)
        }
    }
}

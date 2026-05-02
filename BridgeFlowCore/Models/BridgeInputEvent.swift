import Foundation

public enum BridgeInputEvent: Codable, Hashable, Sendable {
    case mouseMove(dx: Double, dy: Double, timestamp: TimeInterval)
    case mouseDown(button: Int, timestamp: TimeInterval)
    case mouseUp(button: Int, timestamp: TimeInterval)
    case scroll(dx: Double, dy: Double, timestamp: TimeInterval)
    case keyDown(keyCode: UInt16, modifiers: BridgeModifierFlags, timestamp: TimeInterval)
    case keyUp(keyCode: UInt16, modifiers: BridgeModifierFlags, timestamp: TimeInterval)
    case flagsChanged(modifiers: BridgeModifierFlags, timestamp: TimeInterval)
    case heartbeat(timestamp: TimeInterval)
    case releaseAllKeys(timestamp: TimeInterval)

    private enum CodingKeys: String, CodingKey {
        case type
        case dx
        case dy
        case button
        case keyCode
        case modifiers
        case timestamp
    }

    private enum EventType: String, Codable {
        case mouseMove
        case mouseDown
        case mouseUp
        case scroll
        case keyDown
        case keyUp
        case flagsChanged
        case heartbeat
        case releaseAllKeys
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(EventType.self, forKey: .type)

        switch type {
        case .mouseMove:
            self = .mouseMove(
                dx: try container.decode(Double.self, forKey: .dx),
                dy: try container.decode(Double.self, forKey: .dy),
                timestamp: try container.decode(TimeInterval.self, forKey: .timestamp)
            )
        case .mouseDown:
            self = .mouseDown(
                button: try container.decode(Int.self, forKey: .button),
                timestamp: try container.decode(TimeInterval.self, forKey: .timestamp)
            )
        case .mouseUp:
            self = .mouseUp(
                button: try container.decode(Int.self, forKey: .button),
                timestamp: try container.decode(TimeInterval.self, forKey: .timestamp)
            )
        case .scroll:
            self = .scroll(
                dx: try container.decode(Double.self, forKey: .dx),
                dy: try container.decode(Double.self, forKey: .dy),
                timestamp: try container.decode(TimeInterval.self, forKey: .timestamp)
            )
        case .keyDown:
            self = .keyDown(
                keyCode: try container.decode(UInt16.self, forKey: .keyCode),
                modifiers: try container.decode(BridgeModifierFlags.self, forKey: .modifiers),
                timestamp: try container.decode(TimeInterval.self, forKey: .timestamp)
            )
        case .keyUp:
            self = .keyUp(
                keyCode: try container.decode(UInt16.self, forKey: .keyCode),
                modifiers: try container.decode(BridgeModifierFlags.self, forKey: .modifiers),
                timestamp: try container.decode(TimeInterval.self, forKey: .timestamp)
            )
        case .flagsChanged:
            self = .flagsChanged(
                modifiers: try container.decode(BridgeModifierFlags.self, forKey: .modifiers),
                timestamp: try container.decode(TimeInterval.self, forKey: .timestamp)
            )
        case .heartbeat:
            self = .heartbeat(timestamp: try container.decode(TimeInterval.self, forKey: .timestamp))
        case .releaseAllKeys:
            self = .releaseAllKeys(timestamp: try container.decode(TimeInterval.self, forKey: .timestamp))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .mouseMove(dx, dy, timestamp):
            try container.encode(EventType.mouseMove, forKey: .type)
            try container.encode(dx, forKey: .dx)
            try container.encode(dy, forKey: .dy)
            try container.encode(timestamp, forKey: .timestamp)
        case let .mouseDown(button, timestamp):
            try container.encode(EventType.mouseDown, forKey: .type)
            try container.encode(button, forKey: .button)
            try container.encode(timestamp, forKey: .timestamp)
        case let .mouseUp(button, timestamp):
            try container.encode(EventType.mouseUp, forKey: .type)
            try container.encode(button, forKey: .button)
            try container.encode(timestamp, forKey: .timestamp)
        case let .scroll(dx, dy, timestamp):
            try container.encode(EventType.scroll, forKey: .type)
            try container.encode(dx, forKey: .dx)
            try container.encode(dy, forKey: .dy)
            try container.encode(timestamp, forKey: .timestamp)
        case let .keyDown(keyCode, modifiers, timestamp):
            try container.encode(EventType.keyDown, forKey: .type)
            try container.encode(keyCode, forKey: .keyCode)
            try container.encode(modifiers, forKey: .modifiers)
            try container.encode(timestamp, forKey: .timestamp)
        case let .keyUp(keyCode, modifiers, timestamp):
            try container.encode(EventType.keyUp, forKey: .type)
            try container.encode(keyCode, forKey: .keyCode)
            try container.encode(modifiers, forKey: .modifiers)
            try container.encode(timestamp, forKey: .timestamp)
        case let .flagsChanged(modifiers, timestamp):
            try container.encode(EventType.flagsChanged, forKey: .type)
            try container.encode(modifiers, forKey: .modifiers)
            try container.encode(timestamp, forKey: .timestamp)
        case let .heartbeat(timestamp):
            try container.encode(EventType.heartbeat, forKey: .type)
            try container.encode(timestamp, forKey: .timestamp)
        case let .releaseAllKeys(timestamp):
            try container.encode(EventType.releaseAllKeys, forKey: .type)
            try container.encode(timestamp, forKey: .timestamp)
        }
    }
}

import CoreGraphics
import Foundation

public enum EventNormalizer {
    public static func normalise(
        event: CGEvent,
        type: CGEventType,
        timestamp: TimeInterval = Date().timeIntervalSince1970
    ) -> BridgeInputEvent? {
        switch type {
        case .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            return .mouseMove(
                dx: event.getDoubleValueField(.mouseEventDeltaX),
                dy: event.getDoubleValueField(.mouseEventDeltaY),
                timestamp: timestamp
            )
        case .leftMouseDown:
            return .mouseDown(button: 0, timestamp: timestamp)
        case .leftMouseUp:
            return .mouseUp(button: 0, timestamp: timestamp)
        case .rightMouseDown:
            return .mouseDown(button: 1, timestamp: timestamp)
        case .rightMouseUp:
            return .mouseUp(button: 1, timestamp: timestamp)
        case .otherMouseDown:
            return .mouseDown(
                button: Int(event.getIntegerValueField(.mouseEventButtonNumber)),
                timestamp: timestamp
            )
        case .otherMouseUp:
            return .mouseUp(
                button: Int(event.getIntegerValueField(.mouseEventButtonNumber)),
                timestamp: timestamp
            )
        case .scrollWheel:
            return .scroll(
                dx: event.getDoubleValueField(.scrollWheelEventDeltaAxis2),
                dy: event.getDoubleValueField(.scrollWheelEventDeltaAxis1),
                timestamp: timestamp
            )
        case .keyDown:
            return .keyDown(
                keyCode: UInt16(event.getIntegerValueField(.keyboardEventKeycode)),
                modifiers: BridgeModifierFlags.from(event.flags),
                timestamp: timestamp
            )
        case .keyUp:
            return .keyUp(
                keyCode: UInt16(event.getIntegerValueField(.keyboardEventKeycode)),
                modifiers: BridgeModifierFlags.from(event.flags),
                timestamp: timestamp
            )
        case .flagsChanged:
            return .flagsChanged(
                modifiers: BridgeModifierFlags.from(event.flags),
                timestamp: timestamp
            )
        default:
            return nil
        }
    }

    public static func normalize(
        event: CGEvent,
        type: CGEventType,
        timestamp: TimeInterval = Date().timeIntervalSince1970
    ) -> BridgeInputEvent? {
        normalise(event: event, type: type, timestamp: timestamp)
    }

    public static func isCancelHotKey(_ input: BridgeInputEvent) -> Bool {
        guard case let .keyDown(keyCode, modifiers, _) = input else {
            return false
        }
        return keyCode == 53
            && modifiers.contains(.control)
            && modifiers.contains(.option)
            && modifiers.contains(.command)
    }
}

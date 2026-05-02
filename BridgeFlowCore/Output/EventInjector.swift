import CoreGraphics
import Foundation

public protocol EventInjecting: AnyObject {
    func inject(_ event: BridgeInputEvent)
    func releaseAllKeys()
}

public final class EventInjector: EventInjecting {
    private let cursorController: CursorControlling
    private var tracker = ModifierStateTracker()

    public init(cursorController: CursorControlling = CursorController()) {
        self.cursorController = cursorController
    }

    deinit {
        releaseAllKeys()
    }

    public func inject(_ event: BridgeInputEvent) {
        switch event {
        case let .mouseMove(dx, dy, _):
            cursorController.moveBy(dx: dx, dy: dy)
        case let .mouseDown(button, _):
            postMouse(button: button, down: true)
        case let .mouseUp(button, _):
            postMouse(button: button, down: false)
        case let .scroll(dx, dy, _):
            postScroll(dx: dx, dy: dy)
        case let .keyDown(keyCode, modifiers, _):
            postKey(keyCode: keyCode, down: true, modifiers: modifiers)
            tracker.record(event)
        case let .keyUp(keyCode, modifiers, _):
            postKey(keyCode: keyCode, down: false, modifiers: modifiers)
            tracker.record(event)
        case let .flagsChanged(modifiers, _):
            postModifierChanges(from: tracker.activeModifiers, to: modifiers)
            tracker.record(event)
        case .heartbeat:
            break
        case .releaseAllKeys:
            releaseAllKeys()
        }
    }

    public func releaseAllKeys() {
        let keyCodes = tracker.activeKeyCodes.sorted()
        let modifiers = tracker.activeModifiers

        for keyCode in keyCodes {
            postKey(keyCode: keyCode, down: false, modifiers: [])
        }
        postModifierChanges(from: modifiers, to: [])

        _ = tracker.releaseAll(timestamp: Date().timeIntervalSince1970)
    }

    private func postMouse(button: Int, down: Bool) {
        let cgButton = mouseButton(for: button)
        let type = mouseEventType(button: button, down: down)
        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: type,
            mouseCursorPosition: cursorController.currentPosition(),
            mouseButton: cgButton
        ) else {
            return
        }
        event.post(tap: .cghidEventTap)
    }

    private func postScroll(dx: Double, dy: Double) {
        let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 2,
            wheel1: Int32(dy),
            wheel2: Int32(dx),
            wheel3: 0
        )
        event?.post(tap: .cghidEventTap)
    }

    private func postKey(keyCode: UInt16, down: Bool, modifiers: BridgeModifierFlags) {
        guard let event = CGEvent(
            keyboardEventSource: nil,
            virtualKey: CGKeyCode(keyCode),
            keyDown: down
        ) else {
            return
        }
        event.flags = modifiers.cgEventFlags
        event.post(tap: .cghidEventTap)
    }

    private func postModifierChanges(from old: BridgeModifierFlags, to new: BridgeModifierFlags) {
        for (flag, keyCode) in Self.modifierKeyCodes {
            if old.contains(flag), !new.contains(flag) {
                postKey(keyCode: keyCode, down: false, modifiers: new)
            } else if !old.contains(flag), new.contains(flag) {
                postKey(keyCode: keyCode, down: true, modifiers: new)
            }
        }
    }

    private func mouseButton(for button: Int) -> CGMouseButton {
        switch button {
        case 0:
            .left
        case 1:
            .right
        default:
            .center
        }
    }

    private func mouseEventType(button: Int, down: Bool) -> CGEventType {
        switch (button, down) {
        case (0, true):
            .leftMouseDown
        case (0, false):
            .leftMouseUp
        case (1, true):
            .rightMouseDown
        case (1, false):
            .rightMouseUp
        case (_, true):
            .otherMouseDown
        case (_, false):
            .otherMouseUp
        }
    }

    private static let modifierKeyCodes: [(BridgeModifierFlags, UInt16)] = [
        (.shift, 56),
        (.control, 59),
        (.option, 58),
        (.command, 55),
        (.capsLock, 57),
        (.function, 63)
    ]
}

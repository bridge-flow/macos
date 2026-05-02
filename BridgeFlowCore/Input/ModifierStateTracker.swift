import Foundation

public struct ModifierStateTracker {
    public private(set) var activeKeyCodes: Set<UInt16>
    public private(set) var activeModifiers: BridgeModifierFlags

    public init(activeKeyCodes: Set<UInt16> = [], activeModifiers: BridgeModifierFlags = []) {
        self.activeKeyCodes = activeKeyCodes
        self.activeModifiers = activeModifiers
    }

    public mutating func record(_ event: BridgeInputEvent) {
        switch event {
        case let .keyDown(keyCode, modifiers, _):
            activeKeyCodes.insert(keyCode)
            activeModifiers = modifiers
        case let .keyUp(keyCode, modifiers, _):
            activeKeyCodes.remove(keyCode)
            activeModifiers = modifiers
        case let .flagsChanged(modifiers, _):
            activeModifiers = modifiers
        case .releaseAllKeys:
            activeKeyCodes.removeAll()
            activeModifiers = []
        case .mouseMove, .mouseDown, .mouseUp, .scroll, .heartbeat:
            break
        }
    }

    public mutating func releaseAll(timestamp: TimeInterval) -> [BridgeInputEvent] {
        var releases = activeKeyCodes
            .sorted()
            .map { BridgeInputEvent.keyUp(keyCode: $0, modifiers: [], timestamp: timestamp) }

        if !activeModifiers.isEmpty {
            releases.append(.flagsChanged(modifiers: [], timestamp: timestamp))
        }

        activeKeyCodes.removeAll()
        activeModifiers = []

        return releases
    }
}

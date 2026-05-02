import CoreGraphics
import Foundation

public struct BridgeModifierFlags: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    public static let command = BridgeModifierFlags(rawValue: 1 << 0)
    public static let option = BridgeModifierFlags(rawValue: 1 << 1)
    public static let control = BridgeModifierFlags(rawValue: 1 << 2)
    public static let shift = BridgeModifierFlags(rawValue: 1 << 3)
    public static let capsLock = BridgeModifierFlags(rawValue: 1 << 4)
    public static let function = BridgeModifierFlags(rawValue: 1 << 5)

    public static func from(_ flags: CGEventFlags) -> BridgeModifierFlags {
        var modifiers: BridgeModifierFlags = []
        if flags.contains(.maskCommand) { modifiers.insert(.command) }
        if flags.contains(.maskAlternate) { modifiers.insert(.option) }
        if flags.contains(.maskControl) { modifiers.insert(.control) }
        if flags.contains(.maskShift) { modifiers.insert(.shift) }
        if flags.contains(.maskAlphaShift) { modifiers.insert(.capsLock) }
        if flags.contains(.maskSecondaryFn) { modifiers.insert(.function) }
        return modifiers
    }

    public var cgEventFlags: CGEventFlags {
        var flags = CGEventFlags()
        if contains(.command) { flags.insert(.maskCommand) }
        if contains(.option) { flags.insert(.maskAlternate) }
        if contains(.control) { flags.insert(.maskControl) }
        if contains(.shift) { flags.insert(.maskShift) }
        if contains(.capsLock) { flags.insert(.maskAlphaShift) }
        if contains(.function) { flags.insert(.maskSecondaryFn) }
        return flags
    }
}

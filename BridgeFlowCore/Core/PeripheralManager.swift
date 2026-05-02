import Foundation
import IOKit.hid

public protocol PeripheralProviding {
    func connectedInputDevices() -> [PeripheralDevice]
}

public final class PeripheralManager: PeripheralProviding {
    public init() {}

    public func connectedInputDevices() -> [PeripheralDevice] {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatchingMultiple(manager, matchingDictionaries() as CFArray)

        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard result == kIOReturnSuccess else {
            return []
        }
        defer { IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone)) }

        guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
            return []
        }

        var seenIDs = Set<String>()
        return devices
            .compactMap(device(from:))
            .filter { device in
                if seenIDs.contains(device.id) {
                    return false
                }
                seenIDs.insert(device.id)
                return true
            }
            .sorted { lhs, rhs in
                if lhs.kind.rawValue == rhs.kind.rawValue {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.kind.rawValue < rhs.kind.rawValue
            }
    }

    private func device(from hidDevice: IOHIDDevice) -> PeripheralDevice? {
        let usage = intProperty(kIOHIDPrimaryUsageKey, from: hidDevice)
        let kind = peripheralKind(primaryUsage: usage, productName: stringProperty(kIOHIDProductKey, from: hidDevice))
        guard kind != .unknown else {
            return nil
        }

        let name = stringProperty(kIOHIDProductKey, from: hidDevice)
        let manufacturer = stringProperty(kIOHIDManufacturerKey, from: hidDevice)
        let transport = stringProperty(kIOHIDTransportKey, from: hidDevice)

        return PeripheralDevice(
            vendorID: intProperty(kIOHIDVendorIDKey, from: hidDevice),
            productID: intProperty(kIOHIDProductIDKey, from: hidDevice),
            locationID: intProperty(kIOHIDLocationIDKey, from: hidDevice),
            name: name,
            manufacturer: manufacturer,
            kind: kind,
            transport: transport,
            isBuiltIn: isBuiltIn(name: name, transport: transport)
        )
    }

    private func matchingDictionaries() -> [[String: Any]] {
        [
            matchingDictionary(usage: kHIDUsage_GD_Keyboard),
            matchingDictionary(usage: kHIDUsage_GD_Keypad),
            matchingDictionary(usage: kHIDUsage_GD_Mouse),
            matchingDictionary(usage: kHIDUsage_GD_Pointer),
            matchingDictionary(usage: kHIDUsage_GD_GamePad),
            matchingDictionary(usage: kHIDUsage_GD_Joystick)
        ]
    }

    private func matchingDictionary(usage: Int) -> [String: Any] {
        [
            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey as String: usage
        ]
    }

    private func peripheralKind(primaryUsage: Int?, productName: String?) -> PeripheralKind {
        switch primaryUsage {
        case kHIDUsage_GD_Keyboard, kHIDUsage_GD_Keypad:
            return .keyboard
        case kHIDUsage_GD_Mouse:
            return .mouse
        case kHIDUsage_GD_Pointer:
            return productName?.localizedCaseInsensitiveContains("trackpad") == true ? .trackpad : .mouse
        case kHIDUsage_GD_GamePad, kHIDUsage_GD_Joystick:
            return .gameController
        default:
            if productName?.localizedCaseInsensitiveContains("trackpad") == true {
                return .trackpad
            }
            return .unknown
        }
    }

    private func isBuiltIn(name: String?, transport: String?) -> Bool {
        let combined = [name, transport]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

        return combined.contains("built-in")
            || combined.contains("internal")
            || combined.contains("apple internal")
    }

    private func stringProperty(_ key: String, from device: IOHIDDevice) -> String? {
        IOHIDDeviceGetProperty(device, key as CFString) as? String
    }

    private func intProperty(_ key: String, from device: IOHIDDevice) -> Int? {
        if let number = IOHIDDeviceGetProperty(device, key as CFString) as? NSNumber {
            return number.intValue
        }
        return nil
    }
}

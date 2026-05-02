import Foundation

public enum PeripheralKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case keyboard
    case mouse
    case trackpad
    case gameController
    case unknown

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .keyboard:
            "Keyboard"
        case .mouse:
            "Mouse"
        case .trackpad:
            "Trackpad"
        case .gameController:
            "Game controller"
        case .unknown:
            "Input device"
        }
    }

    public var systemImage: String {
        switch self {
        case .keyboard:
            "keyboard"
        case .mouse:
            "computermouse"
        case .trackpad:
            "rectangle.and.hand.point.up.left"
        case .gameController:
            "gamecontroller"
        case .unknown:
            "cursorarrow"
        }
    }
}

public struct PeripheralDevice: Codable, Hashable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var manufacturer: String?
    public var kind: PeripheralKind
    public var transport: String?
    public var isBuiltIn: Bool

    public init(
        id: String,
        name: String,
        manufacturer: String?,
        kind: PeripheralKind,
        transport: String?,
        isBuiltIn: Bool
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? kind.displayName : name
        self.manufacturer = manufacturer?.nilIfBlank
        self.kind = kind
        self.transport = transport?.nilIfBlank
        self.isBuiltIn = isBuiltIn
    }

    public init(
        vendorID: Int?,
        productID: Int?,
        locationID: Int?,
        name: String?,
        manufacturer: String?,
        kind: PeripheralKind,
        transport: String?,
        isBuiltIn: Bool
    ) {
        let resolvedName = name?.nilIfBlank ?? kind.displayName
        self.init(
            id: Self.stableIdentifier(
                vendorID: vendorID,
                productID: productID,
                locationID: locationID,
                name: resolvedName
            ),
            name: resolvedName,
            manufacturer: manufacturer,
            kind: kind,
            transport: transport,
            isBuiltIn: isBuiltIn
        )
    }

    public static func stableIdentifier(
        vendorID: Int?,
        productID: Int?,
        locationID: Int?,
        name: String
    ) -> String {
        let components = [
            vendorID.map(String.init) ?? "unknown-vendor",
            productID.map(String.init) ?? "unknown-product",
            locationID.map(String.init) ?? "unknown-location",
            name.normalisedPeripheralComponent
        ]
        return "hid:" + components.joined(separator: ":")
    }

    public var detailText: String {
        let parts = [manufacturer, transport, isBuiltIn ? "Built-in" : nil].compactMap(\.self)
        return parts.isEmpty ? kind.displayName : parts.joined(separator: " - ")
    }

    public var sharingText: String {
        isBuiltIn ? "Shared from this Mac when active" : "Shared between trusted Macs when active"
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var normalisedPeripheralComponent: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}

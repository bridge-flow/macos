import SwiftUI

enum BridgeFlowPalette {
    static let graphite = Color(hex: 0x07080A)
    static let panel = Color(hex: 0x11131A)
    static let panelElevated = Color(hex: 0x171A22)
    static let textPrimary = Color(hex: 0xF5F7FF)
    static let textSecondary = Color(hex: 0x9AA3B5)
    static let blue = Color(hex: 0x1F6BFF)
    static let cyan = Color(hex: 0x19D1FA)
    static let violet = Color(hex: 0x9459FF)
    static let success = Color(hex: 0x32D583)
    static let warning = Color(hex: 0xFDB022)
    static let danger = Color(hex: 0xF97066)

    static let accentGradient = LinearGradient(
        colors: [blue, cyan, violet],
        startPoint: .leading,
        endPoint: .trailing
    )
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

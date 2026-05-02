import SwiftUI

struct GradientButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(BridgeFlowPalette.textPrimary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .frame(minWidth: 132)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(BridgeFlowPalette.accentGradient)
                        .shadow(color: BridgeFlowPalette.cyan.opacity(0.24), radius: 12, x: 0, y: 6)
                )
        }
        .buttonStyle(.plain)
    }
}

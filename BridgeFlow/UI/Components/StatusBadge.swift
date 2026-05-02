import BridgeFlowCore
import SwiftUI

struct StatusBadge: View {
    let status: ConnectionStatus

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(colour)
                .frame(width: 8, height: 8)
                .shadow(color: colour.opacity(0.55), radius: 5)

            Text(status.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BridgeFlowPalette.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(colour.opacity(0.14))
                .overlay(Capsule().stroke(colour.opacity(0.35), lineWidth: 1))
        )
    }

    private var colour: Color {
        switch status {
        case .active, .connected:
            BridgeFlowPalette.success
        case .waiting, .connecting:
            BridgeFlowPalette.warning
        case .error:
            BridgeFlowPalette.danger
        case .stopped:
            BridgeFlowPalette.textSecondary
        }
    }
}

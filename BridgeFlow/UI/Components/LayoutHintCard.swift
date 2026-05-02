import BridgeFlowCore
import SwiftUI

struct LayoutHintCard: View {
    let edge: ScreenEdge
    let localName: String
    let remoteName: String

    var body: some View {
        GlassCard {
            HStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(BridgeFlowPalette.accentGradient.opacity(0.18))
                    Image(systemName: edge.arrowSystemImage)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(BridgeFlowPalette.cyan)
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 7) {
                    Text(edge.placementDescription)
                        .font(.headline)
                        .foregroundStyle(BridgeFlowPalette.textPrimary)

                    Text(edge.activationInstruction)
                        .font(.callout)
                        .foregroundStyle(BridgeFlowPalette.textSecondary)

                    Text("\(localName) -> \(remoteName)")
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(BridgeFlowPalette.textSecondary)
                }

                Spacer()
            }
        }
    }
}

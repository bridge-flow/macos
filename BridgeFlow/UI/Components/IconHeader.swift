import SwiftUI

struct IconHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image("BridgeFlowIcon", bundle: BridgeFlowResources.bundle)
                .resizable()
                .interpolation(.high)
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .shadow(color: BridgeFlowPalette.cyan.opacity(0.24), radius: 14)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(BridgeFlowPalette.textPrimary)

                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(BridgeFlowPalette.textSecondary)
            }

            Spacer()
        }
    }
}

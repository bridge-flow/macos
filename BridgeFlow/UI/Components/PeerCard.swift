import BridgeFlowCore
import Foundation
import SwiftUI

struct PeerCard: View {
    let peer: PeerSnapshot
    let connect: () -> Void
    let disconnect: () -> Void
    let trust: () -> Void
    let removeTrust: () -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(BridgeFlowPalette.accentGradient.opacity(0.18))
                    Image(systemName: "desktopcomputer")
                        .font(.title2)
                        .foregroundStyle(BridgeFlowPalette.cyan)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(peer.name)
                            .font(.headline)
                            .foregroundStyle(BridgeFlowPalette.textPrimary)
                        StatusBadge(status: peer.status)
                    }

                    Text(peer.endpoint)
                        .font(.caption)
                        .foregroundStyle(BridgeFlowPalette.textSecondary)

                    HStack(spacing: 10) {
                        Text(peer.trusted ? "Trusted" : "Not trusted")
                        if let latency = peer.latencyMs {
                            Text(String(format: "%.0f ms", latency))
                        }
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(BridgeFlowPalette.textSecondary)
                }

                Spacer()

                Button(peer.trusted ? "Remove" : "Trust") {
                    peer.trusted ? removeTrust() : trust()
                }

                if peer.status == .available || peer.status == .stopped {
                    Button("Connect", action: connect)
                } else {
                    Button("Disconnect", action: disconnect)
                }
            }
        }
    }
}

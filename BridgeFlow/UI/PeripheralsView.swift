import BridgeFlowCore
import SwiftUI

struct PeripheralsView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .center) {
                    IconHeader(title: "Peripherals", subtitle: "Input devices visible to BridgeFlow on each Mac.")
                    Spacer()
                    Button {
                        appState.refreshPeripherals()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }

                PeripheralGroupCard(
                    title: "This Mac",
                    subtitle: appState.localPeerInfo.name,
                    devices: appState.localPeripherals,
                    emptyText: "No keyboard, mouse, or trackpad was reported by macOS."
                )

                VStack(alignment: .leading, spacing: 14) {
                    Text("Connected Macs")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(BridgeFlowPalette.textPrimary)

                    if appState.peers.isEmpty {
                        GlassCard {
                            HStack(spacing: 10) {
                                Image(systemName: "desktopcomputer.trianglebadge.exclamationmark")
                                    .foregroundStyle(BridgeFlowPalette.textSecondary)
                                Text("No peer inventory received yet")
                                    .foregroundStyle(BridgeFlowPalette.textSecondary)
                                Spacer()
                            }
                        }
                    } else {
                        ForEach(appState.peers) { peer in
                            PeripheralGroupCard(
                                title: peer.name,
                                subtitle: peer.endpoint,
                                devices: appState.remotePeripheralsByPeerID[peer.id] ?? [],
                                emptyText: "Waiting for this Mac to send its peripheral inventory."
                            )
                        }
                    }
                }
            }
            .padding(28)
        }
    }
}

private struct PeripheralGroupCard: View {
    let title: String
    let subtitle: String
    let devices: [PeripheralDevice]
    let emptyText: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(BridgeFlowPalette.textPrimary)
                        Text(subtitle)
                            .font(.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                            .foregroundStyle(BridgeFlowPalette.textSecondary)
                    }

                    Spacer()

                    Text("\(devices.count) devices")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BridgeFlowPalette.textSecondary)
                }

                if devices.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "keyboard.badge.ellipsis")
                        Text(emptyText)
                        Spacer()
                    }
                    .font(.callout)
                    .foregroundStyle(BridgeFlowPalette.textSecondary)
                } else {
                    VStack(spacing: 10) {
                        ForEach(devices) { device in
                            PeripheralRow(device: device)
                        }
                    }
                }
            }
        }
    }
}

private struct PeripheralRow: View {
    let device: PeripheralDevice

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(BridgeFlowPalette.accentGradient.opacity(0.16))
                Image(systemName: device.kind.systemImage)
                    .font(.title3)
                    .foregroundStyle(BridgeFlowPalette.cyan)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .foregroundStyle(BridgeFlowPalette.textPrimary)

                Text(device.detailText)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .foregroundStyle(BridgeFlowPalette.textSecondary)
            }

            Spacer()

            Text(device.kind.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BridgeFlowPalette.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(.white.opacity(0.06)))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(BridgeFlowPalette.panel.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

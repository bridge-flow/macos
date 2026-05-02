import BridgeFlowCore
import SwiftUI

struct PeersView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var settings: SettingsStore

    init(appState: AppState) {
        self.appState = appState
        _settings = ObservedObject(wrappedValue: appState.settings)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                IconHeader(title: "Peers", subtitle: "Connect trusted Macs on the local network.")

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Manual connection")
                            .font(.headline)
                            .foregroundStyle(BridgeFlowPalette.textPrimary)

                        HStack(spacing: 12) {
                            TextField("IP address or hostname", text: $settings.peerHost)
                                .textFieldStyle(.roundedBorder)

                            TextField("Port", value: $settings.peerPort, format: .number)
                                .frame(width: 88)
                                .textFieldStyle(.roundedBorder)

                            GradientButton(title: "Connect", systemImage: "link") {
                                appState.connectToConfiguredPeer()
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Connected Macs")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(BridgeFlowPalette.textPrimary)

                    if appState.peers.isEmpty {
                        GlassCard {
                            HStack {
                                Image(systemName: "desktopcomputer.trianglebadge.exclamationmark")
                                    .foregroundStyle(BridgeFlowPalette.textSecondary)
                                Text("No peers connected")
                                    .foregroundStyle(BridgeFlowPalette.textSecondary)
                                Spacer()
                            }
                        }
                    } else {
                        ForEach(appState.peers) { peer in
                            PeerCard(
                                peer: peer,
                                disconnect: { appState.disconnect(peerID: peer.id) },
                                trust: { appState.trust(peerID: peer.id) },
                                removeTrust: { appState.removeTrust(peerID: peer.id) }
                            )
                        }
                    }
                }
            }
            .padding(28)
        }
    }
}

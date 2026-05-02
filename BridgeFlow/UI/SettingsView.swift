import BridgeFlowCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var settings: SettingsStore

    init(appState: AppState) {
        self.appState = appState
        _settings = ObservedObject(wrappedValue: appState.settings)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                IconHeader(title: "Settings", subtitle: "Tune how BridgeFlow starts, pairs and switches.")

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Picker("Default mode", selection: $settings.defaultMode) {
                            ForEach(AppMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }

                        TextField("Port", value: $settings.port, format: .number)

                        Toggle("Start on launch", isOn: $settings.startOnLaunch)
                        Toggle("Launch at login", isOn: $settings.launchAtLogin)
                        Toggle("Menu bar only", isOn: $settings.menuBarOnly)
                        Toggle("Show debug logs", isOn: $settings.showDebugLogs)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pairing code")
                            .font(.headline)
                            .foregroundStyle(BridgeFlowPalette.textPrimary)

                        HStack {
                            Text(settings.pairingCode)
                                .font(.system(size: 30, weight: .bold, design: .monospaced))
                                .foregroundStyle(BridgeFlowPalette.textPrimary)
                                .padding(.vertical, 6)
                            Spacer()
                            Button("Regenerate") {
                                settings.regeneratePairingCode()
                            }
                        }
                    }
                }
            }
            .padding(28)
        }
        .foregroundStyle(BridgeFlowPalette.textPrimary)
        .background(BridgeFlowPalette.graphite)
    }
}

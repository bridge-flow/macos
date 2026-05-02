import BridgeFlowCore
import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image("BridgeFlowIcon")
                    .resizable()
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("BridgeFlow")
                        .font(.headline)
                    Text(appState.activePeerName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                StatusBadge(status: appState.connectionStatus)
            }

            Divider()

            Button(appState.isRunning ? "Stop" : "Start") {
                appState.isRunning ? appState.stop() : appState.start()
            }

            Button("Switch to Local") {
                appState.switchToLocal()
            }
            .disabled(appState.activePeerID == nil)

            Button("Open BridgeFlow") {
                openWindow(id: "main")
                MenuBarController.showMainWindow()
            }

            Divider()

            Button("Quit") {
                MenuBarController.quit()
            }
        }
        .padding(14)
        .frame(width: 310)
    }
}

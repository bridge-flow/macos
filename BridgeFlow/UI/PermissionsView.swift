import BridgeFlowCore
import SwiftUI

struct PermissionsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var permissions: PermissionManager

    init(appState: AppState) {
        self.appState = appState
        _permissions = ObservedObject(wrappedValue: appState.permissions)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                IconHeader(title: "Permissions", subtitle: "BridgeFlow needs trusted access for global input capture and injection.")

                PermissionRow(
                    title: "Accessibility",
                    description: "Required to post keyboard and mouse events on the client Mac.",
                    granted: permissions.snapshot.accessibilityGranted,
                    openSettings: permissions.openAccessibilitySettings,
                    request: permissions.requestAccessibility
                )

                PermissionRow(
                    title: "Input Monitoring",
                    description: "Required to listen for global keyboard and mouse events on the host Mac.",
                    granted: permissions.snapshot.inputMonitoringGranted,
                    openSettings: permissions.openInputMonitoringSettings,
                    request: { _ = permissions.requestInputMonitoring() }
                )

                Button {
                    _ = permissions.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            .padding(28)
        }
    }
}

private struct PermissionRow: View {
    let title: String
    let description: String
    let granted: Bool
    let openSettings: () -> Void
    let request: () -> Void

    var body: some View {
        GlassCard {
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: granted ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .font(.largeTitle)
                    .foregroundStyle(granted ? BridgeFlowPalette.success : BridgeFlowPalette.warning)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(BridgeFlowPalette.textPrimary)
                    Text(description)
                        .font(.callout)
                        .foregroundStyle(BridgeFlowPalette.textSecondary)
                }

                Spacer()

                if granted {
                    StatusBadge(status: .connected)
                } else {
                    Button("Request", action: request)
                    Button("Open System Settings", action: openSettings)
                }
            }
        }
    }
}

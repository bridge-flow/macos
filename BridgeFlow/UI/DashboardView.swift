import BridgeFlowCore
import Foundation
import SwiftUI

struct DashboardView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var settings: SettingsStore
    @ObservedObject private var permissions: PermissionManager

    init(appState: AppState) {
        self.appState = appState
        _settings = ObservedObject(wrappedValue: appState.settings)
        _permissions = ObservedObject(wrappedValue: appState.permissions)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                IconHeader(title: "BridgeFlow", subtitle: "One flow. Every Mac.")

                HStack(spacing: 12) {
                    GradientButton(
                        title: appState.isRunning ? "Stop" : "Start",
                        systemImage: appState.isRunning ? "stop.fill" : "play.fill"
                    ) {
                        appState.isRunning ? appState.stop() : appState.start()
                    }

                    Button {
                        appState.switchToLocal()
                    } label: {
                        Label("Switch to Local", systemImage: "cursorarrow.click.2")
                            .font(.headline)
                    }
                    .disabled(appState.activePeerID == nil)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 16)], spacing: 16) {
                    MetricCard(title: "Status", value: appState.connectionStatus.displayName, symbol: "dot.radiowaves.left.and.right")
                    MetricCard(title: "This Mac", value: appState.localPeerInfo.name, symbol: "macbook")
                    MetricCard(title: "Active Peer", value: appState.activePeerName, symbol: "cursorarrow.motionlines")
                    MetricCard(title: "Mode", value: settings.defaultMode.displayName, symbol: "rectangle.2.swap")
                    MetricCard(title: "Latency", value: latencyText, symbol: "speedometer")
                    MetricCard(title: "Permissions", value: permissionsText, symbol: "lock.shield")
                    MetricCard(title: "Input Capture", value: appState.inputCaptureStatus.displayName, symbol: "keyboard.badge.eye")
                    MetricCard(title: "Remote Position", value: settings.remotePosition.compactPlacementLabel, symbol: settings.remotePosition.arrowSystemImage)
                    MetricCard(title: "Peripherals", value: "\(appState.localPeripherals.count) local", symbol: "keyboard")
                }

                if appState.inputCaptureStatus == .permissionMissing {
                    GlassCard {
                        HStack(spacing: 14) {
                            Image(systemName: "lock.trianglebadge.exclamationmark")
                                .font(.title2)
                                .foregroundStyle(BridgeFlowPalette.warning)

                            VStack(alignment: .leading, spacing: 5) {
                                Text("Input capture is blocked")
                                    .font(.headline)
                                    .foregroundStyle(BridgeFlowPalette.textPrimary)
                                Text(appState.inputCaptureStatus.message)
                                    .font(.callout)
                                    .foregroundStyle(BridgeFlowPalette.textSecondary)
                            }

                            Spacer()

                            Button("Open Permissions") {
                                permissions.openInputMonitoringSettings()
                            }
                        }
                    }
                }

                if let lastError = appState.lastError {
                    GlassCard {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(BridgeFlowPalette.warning)
                            Text(lastError)
                                .foregroundStyle(BridgeFlowPalette.textPrimary)
                            Spacer()
                        }
                    }
                }
            }
            .padding(28)
        }
    }

    private var latencyText: String {
        guard let latency = appState.latencyMs else { return "-" }
        return String(format: "%.0f ms", latency)
    }

    private var permissionsText: String {
        permissions.snapshot.accessibilityGranted && permissions.snapshot.inputMonitoringGranted ? "Ready" : "Action needed"
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: symbol)
                        .font(.title3)
                        .foregroundStyle(BridgeFlowPalette.cyan)
                    Spacer()
                }

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BridgeFlowPalette.textSecondary)

                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
                    .foregroundStyle(BridgeFlowPalette.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

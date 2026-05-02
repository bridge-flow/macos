import BridgeFlowCore
import Foundation
import SwiftUI

struct LayoutView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var settings: SettingsStore

    init(appState: AppState) {
        self.appState = appState
        _settings = ObservedObject(wrappedValue: appState.settings)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                IconHeader(title: "Layout", subtitle: "Choose where the remote Mac sits relative to this Mac.")

                GlassCard {
                    VStack(spacing: 22) {
                        layoutPreview

                        Picker("Remote position", selection: $settings.remotePosition) {
                            ForEach(ScreenEdge.allCases) { edge in
                                Text(edge.displayName).tag(edge)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Edge switching")
                            .font(.headline)
                            .foregroundStyle(BridgeFlowPalette.textPrimary)

                        Stepper("Activation delay: \(settings.edgeDelayMs) ms", value: $settings.edgeDelayMs, in: 100...1_000, step: 50)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Activation distance: \(String(format: "%.0f", settings.edgeDistancePx)) px")
                            Slider(value: $settings.edgeDistancePx, in: 2...24, step: 1)
                        }
                    }
                    .foregroundStyle(BridgeFlowPalette.textPrimary)
                }
            }
            .padding(28)
        }
    }

    @ViewBuilder
    private var layoutPreview: some View {
        switch settings.remotePosition {
        case .left:
            HStack(spacing: 18) { remoteMac; localMac }
        case .right:
            HStack(spacing: 18) { localMac; remoteMac }
        case .above:
            VStack(spacing: 18) { remoteMac; localMac }
        case .below:
            VStack(spacing: 18) { localMac; remoteMac }
        }
    }

    private var localMac: some View {
        LayoutDeviceCard(title: "This Mac", subtitle: appState.localPeerInfo.name, accent: BridgeFlowPalette.cyan)
    }

    private var remoteMac: some View {
        LayoutDeviceCard(title: "Remote Mac", subtitle: appState.activePeerName == "Local Mac" ? "Configured edge" : appState.activePeerName, accent: BridgeFlowPalette.violet)
    }
}

private struct LayoutDeviceCard: View {
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "display")
                .font(.system(size: 42))
                .foregroundStyle(accent)
            Text(title)
                .font(.headline)
                .foregroundStyle(BridgeFlowPalette.textPrimary)
            Text(subtitle)
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(BridgeFlowPalette.textSecondary)
        }
        .frame(width: 230, height: 150)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(BridgeFlowPalette.panel.opacity(0.92))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(accent.opacity(0.36), lineWidth: 1))
        )
    }
}

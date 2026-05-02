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
                IconHeader(title: "Layout", subtitle: "Drag connected Macs into the same arrangement as your desk.")

                MachineLayoutCanvas(appState: appState)

                GlassCard {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Label(settings.remotePosition.compactPlacementLabel, systemImage: settings.remotePosition.arrowSystemImage)
                                .font(.headline)
                                .foregroundStyle(BridgeFlowPalette.textPrimary)
                            Spacer()
                            StatusBadge(status: appState.connectionStatus)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Stepper("Activation delay: \(settings.edgeDelayMs) ms", value: $settings.edgeDelayMs, in: 100...1_000, step: 50)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Activation distance: \(String(format: "%.0f", settings.edgeDistancePx)) px")
                                Slider(value: $settings.edgeDistancePx, in: 2...24, step: 1)
                            }
                        }
                        .foregroundStyle(BridgeFlowPalette.textPrimary)
                    }
                }
            }
            .padding(28)
        }
    }
}

private struct MachineLayoutCanvas: View {
    @ObservedObject var appState: AppState

    private let cardSize = CGSize(width: 178, height: 108)
    private let canvasHeight: CGFloat = 420

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Desk layout")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(BridgeFlowPalette.textPrimary)
                    Spacer()
                    Text("\(remotePlacements.count) remote")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BridgeFlowPalette.textSecondary)
                }

                GeometryReader { proxy in
                    let size = proxy.size

                    ZStack {
                        layoutBackground
                        connectionLines(in: size)

                        ForEach(orderedPlacements) { placement in
                            MachineNodeCard(
                                placement: placement,
                                isLocal: placement.peerID == appState.localPeerIdentifier,
                                status: peerStatus(for: placement.peerID)
                            )
                            .frame(width: cardSize.width, height: cardSize.height)
                            .position(canvasPoint(for: placement, in: size))
                            .gesture(dragGesture(for: placement, in: size))
                        }

                        if remotePlacements.isEmpty {
                            emptyOverlay
                        }
                    }
                    .coordinateSpace(name: "layoutCanvas")
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .frame(minHeight: canvasHeight)
            }
        }
    }

    private var orderedPlacements: [MachinePlacement] {
        appState.layoutSnapshot.placements.sorted { lhs, rhs in
            if lhs.peerID == appState.localPeerIdentifier {
                return true
            }
            if rhs.peerID == appState.localPeerIdentifier {
                return false
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private var remotePlacements: [MachinePlacement] {
        orderedPlacements.filter { $0.peerID != appState.localPeerIdentifier }
    }

    private var layoutBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BridgeFlowPalette.panel.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )

            VStack {
                edgeLabel("Above", systemImage: "arrow.up")
                Spacer()
                HStack {
                    edgeLabel("Left", systemImage: "arrow.left")
                    Spacer()
                    edgeLabel("Right", systemImage: "arrow.right")
                }
                Spacer()
                edgeLabel("Below", systemImage: "arrow.down")
            }
            .padding(14)
        }
    }

    private var emptyOverlay: some View {
        VStack(spacing: 10) {
            Image(systemName: "desktopcomputer.trianglebadge.exclamationmark")
                .font(.title)
            Text("No connected Macs yet")
                .font(.headline)
        }
        .foregroundStyle(BridgeFlowPalette.textSecondary)
        .offset(y: 126)
    }

    private func edgeLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(BridgeFlowPalette.textSecondary.opacity(0.78))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(.white.opacity(0.05)))
    }

    private func connectionLines(in size: CGSize) -> some View {
        Canvas { context, _ in
            guard let local = appState.layoutSnapshot.placement(for: appState.localPeerIdentifier) else {
                return
            }

            let start = canvasPoint(for: local, in: size)
            for placement in remotePlacements {
                let end = canvasPoint(for: placement, in: size)
                var path = Path()
                path.move(to: start)
                path.addLine(to: end)
                context.stroke(path, with: .color(BridgeFlowPalette.cyan.opacity(0.28)), lineWidth: 2)
            }
        }
    }

    private func canvasPoint(for placement: MachinePlacement, in size: CGSize) -> CGPoint {
        CGPoint(
            x: size.width / 2 + placement.x,
            y: size.height / 2 - placement.y
        )
    }

    private func dragGesture(for placement: MachinePlacement, in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .named("layoutCanvas"))
            .onChanged { value in
                guard placement.peerID != appState.localPeerIdentifier else {
                    return
                }
                appState.updatePeerPlacement(
                    peerID: placement.peerID,
                    x: value.location.x - size.width / 2,
                    y: size.height / 2 - value.location.y
                )
            }
    }

    private func peerStatus(for peerID: UUID) -> ConnectionStatus {
        if peerID == appState.localPeerIdentifier {
            return appState.isRunning ? .active : .waiting
        }
        return appState.peers.first(where: { $0.id == peerID })?.status ?? .available
    }
}

private struct MachineNodeCard: View {
    let placement: MachinePlacement
    let isLocal: Bool
    let status: ConnectionStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: isLocal ? "macbook" : "desktopcomputer")
                    .font(.title3)
                    .foregroundStyle(isLocal ? BridgeFlowPalette.cyan : BridgeFlowPalette.violet)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isLocal ? "This Mac" : "Remote Mac")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BridgeFlowPalette.textSecondary)
                    Text(placement.name)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .foregroundStyle(BridgeFlowPalette.textPrimary)
                }

                Spacer(minLength: 0)
            }

            StatusBadge(status: status)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(BridgeFlowPalette.panelElevated.opacity(isLocal ? 0.96 : 0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke((isLocal ? BridgeFlowPalette.cyan : BridgeFlowPalette.violet).opacity(0.38), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.24), radius: 14, x: 0, y: 8)
    }
}

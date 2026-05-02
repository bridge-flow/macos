import BridgeFlowCore
import Foundation
import SwiftUI

struct FlowView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var settings: SettingsStore
    @ObservedObject private var permissions: PermissionManager
    let openSetup: () -> Void

    private let refreshTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    init(appState: AppState, openSetup: @escaping () -> Void) {
        self.appState = appState
        self.openSetup = openSetup
        _settings = ObservedObject(wrappedValue: appState.settings)
        _permissions = ObservedObject(wrappedValue: appState.permissions)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            HStack(alignment: .top, spacing: 18) {
                FlowBoard(appState: appState)
                    .frame(minWidth: 560, maxWidth: .infinity, minHeight: 500)

                FlowInspector(
                    appState: appState,
                    settings: settings,
                    permissions: permissions,
                    openSetup: openSetup
                )
                .frame(width: 300)
            }
        }
        .padding(24)
        .onReceive(refreshTimer) { _ in
            _ = appState.refreshPermissionsAndResumeInputCaptureIfPossible()
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image("BridgeFlowIcon", bundle: BridgeFlowResources.bundle)
                .resizable()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("BridgeFlow")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(BridgeFlowPalette.textPrimary)
                Text("Arrange your Macs, press Start, then move through the matching screen edge.")
                    .font(.callout)
                    .foregroundStyle(BridgeFlowPalette.textSecondary)
            }

            Spacer()

            StatusBadge(status: appState.connectionStatus)

            Button {
                appState.switchToLocal()
            } label: {
                Label("Local", systemImage: "cursorarrow.click.2")
                    .frame(minWidth: 82)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(appState.activePeerID == nil)

            Button {
                appState.isRunning ? appState.stop() : appState.start()
            } label: {
                Label(appState.isRunning ? "Stop" : "Start", systemImage: appState.isRunning ? "stop.fill" : "play.fill")
                    .frame(minWidth: 92)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(appState.isRunning ? BridgeFlowPalette.danger : BridgeFlowPalette.blue)
        }
    }
}

private struct FlowBoard: View {
    @ObservedObject var appState: AppState

    private let cardSize = CGSize(width: 190, height: 116)

    var body: some View {
        GlassCard {
            GeometryReader { proxy in
                let size = proxy.size

                ZStack {
                    boardBackground
                    connectionLines(in: size)
                    edgeLabels

                    ForEach(orderedPlacements) { placement in
                        FlowMachineCard(
                            placement: placement,
                            isLocal: placement.peerID == appState.localPeerIdentifier,
                            status: peerStatus(for: placement.peerID),
                            peripherals: peripheralCount(for: placement.peerID)
                        )
                        .frame(width: cardSize.width, height: cardSize.height)
                        .position(canvasPoint(for: placement, in: size))
                        .gesture(dragGesture(for: placement, in: size))
                    }

                    if remotePlacements.isEmpty {
                        emptyState
                    }
                }
                .coordinateSpace(name: "flowBoard")
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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

    private var boardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BridgeFlowPalette.panel.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )

            Canvas { context, size in
                let spacing: CGFloat = 48
                var path = Path()
                var x: CGFloat = 0
                while x <= size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += spacing
                }
                var y: CGFloat = 0
                while y <= size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += spacing
                }
                context.stroke(path, with: .color(.white.opacity(0.035)), lineWidth: 1)
            }
        }
    }

    private var edgeLabels: some View {
        VStack {
            FlowEdgeLabel(edge: .above)
            Spacer()
            HStack {
                FlowEdgeLabel(edge: .left)
                Spacer()
                FlowEdgeLabel(edge: .right)
            }
            Spacer()
            FlowEdgeLabel(edge: .below)
        }
        .padding(16)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(BridgeFlowPalette.cyan)
            Text("Waiting for another Mac")
                .font(.headline)
                .foregroundStyle(BridgeFlowPalette.textPrimary)
            Text("Open BridgeFlow on the other Mac, or connect manually from the panel on the right.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(BridgeFlowPalette.textSecondary)
                .frame(maxWidth: 320)
        }
        .offset(y: 148)
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
                context.stroke(path, with: .linearGradient(
                    Gradient(colors: [BridgeFlowPalette.cyan.opacity(0.55), BridgeFlowPalette.violet.opacity(0.45)]),
                    startPoint: start,
                    endPoint: end
                ), lineWidth: 3)
            }
        }
    }

    private func canvasPoint(for placement: MachinePlacement, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(size.width / 2 + placement.x, cardSize.width / 2 + 14), size.width - cardSize.width / 2 - 14),
            y: min(max(size.height / 2 - placement.y, cardSize.height / 2 + 14), size.height - cardSize.height / 2 - 14)
        )
    }

    private func dragGesture(for placement: MachinePlacement, in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .named("flowBoard"))
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

    private func peripheralCount(for peerID: UUID) -> Int {
        if peerID == appState.localPeerIdentifier {
            return appState.localPeripherals.count
        }
        return appState.remotePeripheralsByPeerID[peerID]?.count ?? 0
    }
}

private struct FlowMachineCard: View {
    let placement: MachinePlacement
    let isLocal: Bool
    let status: ConnectionStatus
    let peripherals: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: isLocal ? "macbook" : "desktopcomputer")
                    .font(.system(size: 24, weight: .semibold))
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

                Spacer()
            }

            HStack {
                StatusBadge(status: status)
                Spacer()
                Label("\(peripherals)", systemImage: "keyboard")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BridgeFlowPalette.textSecondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(BridgeFlowPalette.panelElevated.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke((isLocal ? BridgeFlowPalette.cyan : BridgeFlowPalette.violet).opacity(0.42), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 10)
    }
}

private struct FlowEdgeLabel: View {
    let edge: ScreenEdge

    var body: some View {
        Label(edge.displayName, systemImage: edge.arrowSystemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(BridgeFlowPalette.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(.white.opacity(0.055)))
    }
}

private struct FlowInspector: View {
    @ObservedObject var appState: AppState
    @ObservedObject var settings: SettingsStore
    @ObservedObject var permissions: PermissionManager
    let openSetup: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Readiness")
                        .font(.headline)
                        .foregroundStyle(BridgeFlowPalette.textPrimary)

                    ReadinessRow(title: "Accessibility", isReady: permissions.snapshot.accessibilityGranted)
                    ReadinessRow(title: "Input Monitoring", isReady: permissions.snapshot.inputMonitoringGranted)
                    ReadinessRow(title: "Input Capture", isReady: appState.inputCaptureStatus == .running)

                    Button {
                        openSetup()
                    } label: {
                        Label("Review Setup", systemImage: "checklist.checked")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Macs")
                        .font(.headline)
                        .foregroundStyle(BridgeFlowPalette.textPrimary)

                    if appState.peers.isEmpty {
                        Text("No peers discovered yet.")
                            .font(.callout)
                            .foregroundStyle(BridgeFlowPalette.textSecondary)
                    } else {
                        ForEach(appState.peers) { peer in
                            CompactPeerRow(
                                peer: peer,
                                connect: { appState.connect(peerID: peer.id) },
                                disconnect: { appState.disconnect(peerID: peer.id) }
                            )
                        }
                    }

                    Divider().opacity(0.35)

                    TextField("IP or hostname", text: $settings.peerHost)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        TextField("Port", value: $settings.peerPort, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 86)
                        Button("Connect") {
                            appState.connectToConfiguredPeer()
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Shared Devices")
                        .font(.headline)
                        .foregroundStyle(BridgeFlowPalette.textPrimary)
                    DeviceCountRow(title: "This Mac", count: appState.localPeripherals.count)
                    ForEach(appState.peers.prefix(2)) { peer in
                        DeviceCountRow(title: peer.name, count: appState.remotePeripheralsByPeerID[peer.id]?.count ?? 0)
                    }
                }
            }
        }
    }
}

private struct ReadinessRow: View {
    let title: String
    let isReady: Bool

    var body: some View {
        HStack {
            Image(systemName: isReady ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(isReady ? BridgeFlowPalette.success : BridgeFlowPalette.warning)
            Text(title)
                .font(.callout)
                .foregroundStyle(BridgeFlowPalette.textPrimary)
            Spacer()
        }
    }
}

private struct CompactPeerRow: View {
    let peer: PeerSnapshot
    let connect: () -> Void
    let disconnect: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "desktopcomputer")
                .foregroundStyle(BridgeFlowPalette.violet)
            VStack(alignment: .leading, spacing: 2) {
                Text(peer.name)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(BridgeFlowPalette.textPrimary)
                Text(peer.status.displayName)
                    .font(.caption)
                    .foregroundStyle(BridgeFlowPalette.textSecondary)
            }
            Spacer()
            Button(peer.status == .available || peer.status == .stopped ? "Connect" : "Stop") {
                if peer.status == .available || peer.status == .stopped {
                    connect()
                } else {
                    disconnect()
                }
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct DeviceCountRow: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.callout)
                .lineLimit(1)
                .foregroundStyle(BridgeFlowPalette.textPrimary)
            Spacer()
            Label("\(count)", systemImage: "keyboard")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BridgeFlowPalette.textSecondary)
        }
    }
}

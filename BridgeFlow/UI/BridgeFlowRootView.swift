import BridgeFlowCore
import SwiftUI

enum BridgeFlowSection: String, CaseIterable, Identifiable {
    case dashboard
    case peers
    case layout
    case permissions
    case settings
    case logs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .peers: "Peers"
        case .layout: "Layout"
        case .permissions: "Permissions"
        case .settings: "Settings"
        case .logs: "Logs"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "gauge.with.dots.needle.67percent"
        case .peers: "desktopcomputer.and.macbook"
        case .layout: "rectangle.connected.to.line.below"
        case .permissions: "lock.shield"
        case .settings: "slider.horizontal.3"
        case .logs: "list.bullet.rectangle"
        }
    }
}

struct BridgeFlowRootView: View {
    @ObservedObject var appState: AppState
    @State private var selection: BridgeFlowSection? = .dashboard
    @State private var didAutoStart = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    ForEach(BridgeFlowSection.allCases) { section in
                        Label(section.title, systemImage: section.systemImage)
                            .tag(section as BridgeFlowSection?)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
        } detail: {
            ZStack {
                BridgeFlowPalette.graphite.ignoresSafeArea()
                selectedView
            }
        }
        .toolbar {
            ToolbarItemGroup {
                StatusBadge(status: appState.connectionStatus)

                Button {
                    appState.switchToLocal()
                } label: {
                    Label("Switch to Local", systemImage: "cursorarrow.click.2")
                }
                .disabled(appState.activePeerID == nil)

                Button {
                    appState.isRunning ? appState.stop() : appState.start()
                } label: {
                    Label(appState.isRunning ? "Stop" : "Start", systemImage: appState.isRunning ? "stop.fill" : "play.fill")
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            guard !didAutoStart else { return }
            didAutoStart = true
            if appState.settings.startOnLaunch {
                appState.start()
            }
        }
    }

    @ViewBuilder
    private var selectedView: some View {
        switch selection ?? .dashboard {
        case .dashboard:
            DashboardView(appState: appState)
        case .peers:
            PeersView(appState: appState)
        case .layout:
            LayoutView(appState: appState)
        case .permissions:
            PermissionsView(appState: appState)
        case .settings:
            SettingsView(appState: appState)
        case .logs:
            LogsView(appState: appState)
        }
    }
}

import AppKit
import BridgeFlowCore
import SwiftUI

enum BridgeFlowSection: String, CaseIterable, Identifiable {
    case flow
    case setup
    case settings
    case logs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .flow: "Flow"
        case .setup: "Setup"
        case .settings: "Settings"
        case .logs: "Logs"
        }
    }

    var systemImage: String {
        switch self {
        case .flow: "rectangle.connected.to.line.below"
        case .setup: "checklist.checked"
        case .settings: "slider.horizontal.3"
        case .logs: "list.bullet.rectangle"
        }
    }
}

struct BridgeFlowRootView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var settings: SettingsStore
    @State private var selection: BridgeFlowSection? = .flow
    @State private var didAutoStart = false

    init(appState: AppState) {
        self.appState = appState
        _settings = ObservedObject(wrappedValue: appState.settings)
    }

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
        .preferredColorScheme(.dark)
        .task {
            guard !didAutoStart else { return }
            didAutoStart = true
            if !settings.permissionsOnboardingCompleted {
                selection = .setup
                return
            }
            if appState.settings.startOnLaunch {
                appState.start()
            }
        }
        .onChange(of: settings.permissionsOnboardingCompleted) { completed in
            if !completed {
                selection = .setup
            } else if selection == .setup {
                selection = .flow
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            _ = appState.refreshPermissionsAndResumeInputCaptureIfPossible()
        }
    }

    @ViewBuilder
    private var selectedView: some View {
        switch selection ?? .flow {
        case .flow:
            FlowView(appState: appState) {
                selection = .setup
            }
        case .setup:
            PermissionOnboardingView(appState: appState)
        case .settings:
            SettingsView(appState: appState)
        case .logs:
            LogsView(appState: appState)
        }
    }
}

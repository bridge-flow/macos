import BridgeFlowCore
import AppKit
import SwiftUI

@main
struct BridgeFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState: AppState

    init() {
        _appState = StateObject(wrappedValue: AppState())
    }

    var body: some Scene {
        WindowGroup("BridgeFlow", id: "main") {
            BridgeFlowRootView(appState: appState)
                .frame(minWidth: 920, minHeight: 620)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    appState.stop()
                }
        }
        .commands {
            BridgeFlowCommands(appState: appState)
        }

        Settings {
            SettingsView(appState: appState)
                .frame(width: 560)
        }

        MenuBarExtra {
            MenuBarView(appState: appState)
        } label: {
            Image("BridgeFlowIcon", bundle: BridgeFlowResources.bundle)
            Text("BridgeFlow")
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct BridgeFlowCommands: Commands {
    @ObservedObject var appState: AppState

    var body: some Commands {
        CommandMenu("BridgeFlow") {
            Button(appState.isRunning ? "Stop" : "Start") {
                appState.isRunning ? appState.stop() : appState.start()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])

            Button("Switch to Local") {
                appState.switchToLocal()
            }
            .keyboardShortcut(.escape, modifiers: [.command, .control, .option])

            Divider()

            Button("Settings") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
                .keyboardShortcut(",", modifiers: .command)
        }
    }
}

import AppKit

@MainActor
enum MenuBarController {
    static func showMainWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first { $0.title == "BridgeFlow" }?.makeKeyAndOrderFront(nil)
    }

    static func quit() {
        NSApp.terminate(nil)
    }
}

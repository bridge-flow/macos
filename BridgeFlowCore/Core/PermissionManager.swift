import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

@MainActor
public final class PermissionManager: ObservableObject {
    @Published public private(set) var snapshot: PermissionSnapshot

    public init() {
        self.snapshot = PermissionSnapshot(
            accessibilityGranted: AXIsProcessTrusted(),
            inputMonitoringGranted: CGPreflightListenEventAccess()
        )
    }

    @discardableResult
    public func refresh() -> PermissionSnapshot {
        snapshot = PermissionSnapshot(
            accessibilityGranted: AXIsProcessTrusted(),
            inputMonitoringGranted: CGPreflightListenEventAccess()
        )
        return snapshot
    }

    public func requestAccessibility() {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        _ = refresh()
    }

    @discardableResult
    public func requestInputMonitoring() -> Bool {
        let granted = CGRequestListenEventAccess()
        _ = refresh()
        return granted
    }

    public func openAccessibilitySettings() {
        openSettingsPane("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    public func openInputMonitoringSettings() {
        openSettingsPane("x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
    }

    private func openSettingsPane(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

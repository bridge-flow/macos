import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

@MainActor
public final class PermissionManager: ObservableObject {
    @Published public private(set) var snapshot: PermissionSnapshot

    public init() {
        self.snapshot = PermissionSnapshot(
            accessibilityGranted: CGPreflightPostEventAccess(),
            inputMonitoringGranted: CGPreflightListenEventAccess()
        )
    }

    @discardableResult
    public func refresh() -> PermissionSnapshot {
        snapshot = PermissionSnapshot(
            accessibilityGranted: CGPreflightPostEventAccess(),
            inputMonitoringGranted: CGPreflightListenEventAccess()
        )
        return snapshot
    }

    public func requestAccessibility() {
        _ = CGRequestPostEventAccess()
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

    public func openLocalNetworkSettings() {
        openSettingsPane("x-apple.systempreferences:com.apple.preference.security?Privacy_LocalNetwork")
    }

    private func openSettingsPane(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

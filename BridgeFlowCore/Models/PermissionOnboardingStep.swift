import Foundation

public enum PermissionOnboardingStep: String, CaseIterable, Identifiable, Sendable {
    case accessibility
    case inputMonitoring
    case localNetwork

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .accessibility:
            "Accessibility"
        case .inputMonitoring:
            "Input Monitoring"
        case .localNetwork:
            "Local Network"
        }
    }

    public var description: String {
        switch self {
        case .accessibility:
            "Allows BridgeFlow to post keyboard, pointer, click and scroll events on the Mac receiving control."
        case .inputMonitoring:
            "Allows BridgeFlow to capture global keyboard and pointer input on the Mac sharing its devices."
        case .localNetwork:
            "Allows BridgeFlow to discover and connect to trusted Macs on your LAN using Bonjour and TCP."
        }
    }

    public var primaryActionTitle: String {
        switch self {
        case .accessibility:
            "Request Accessibility"
        case .inputMonitoring:
            "Request Input Monitoring"
        case .localNetwork:
            "Start Discovery"
        }
    }

    public var hasNativeRequestAPI: Bool {
        switch self {
        case .accessibility, .inputMonitoring:
            true
        case .localNetwork:
            false
        }
    }

    public var pendingStatusText: String {
        switch self {
        case .accessibility, .inputMonitoring:
            "Needs action"
        case .localNetwork:
            "Waiting for macOS or peer discovery"
        }
    }

    public var systemImage: String {
        switch self {
        case .accessibility:
            "figure.wave"
        case .inputMonitoring:
            "keyboard.badge.eye"
        case .localNetwork:
            "network"
        }
    }
}

public struct PermissionOnboardingProgress: Hashable, Sendable {
    public var snapshot: PermissionSnapshot
    public var localNetworkReady: Bool

    public init(snapshot: PermissionSnapshot, localNetworkReady: Bool) {
        self.snapshot = snapshot
        self.localNetworkReady = localNetworkReady
    }

    public func isComplete(_ step: PermissionOnboardingStep) -> Bool {
        switch step {
        case .accessibility:
            snapshot.accessibilityGranted
        case .inputMonitoring:
            snapshot.inputMonitoringGranted
        case .localNetwork:
            localNetworkReady
        }
    }

    public func firstIncompleteStep() -> PermissionOnboardingStep? {
        PermissionOnboardingStep.allCases.first { !isComplete($0) }
    }

    public func nextStep(afterCompleting step: PermissionOnboardingStep) -> PermissionOnboardingStep? {
        guard isComplete(step) else {
            return step
        }

        let steps = PermissionOnboardingStep.allCases
        guard let index = steps.firstIndex(of: step) else {
            return firstIncompleteStep()
        }

        return steps[(index + 1)...].first { !isComplete($0) }
    }
}

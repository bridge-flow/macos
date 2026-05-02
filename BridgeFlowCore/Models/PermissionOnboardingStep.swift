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
            "Enable Local Network"
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

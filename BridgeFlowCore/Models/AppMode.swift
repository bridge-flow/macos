import Foundation

public enum AppMode: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case host
    case client
    case both

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .host:
            "Host"
        case .client:
            "Client"
        case .both:
            "Both"
        }
    }
}

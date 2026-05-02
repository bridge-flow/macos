import Foundation

public struct PeerInfo: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var hostname: String
    public var appVersion: String
    public var role: AppMode

    public init(id: UUID, name: String, hostname: String, appVersion: String, role: AppMode) {
        self.id = id
        self.name = name
        self.hostname = hostname
        self.appVersion = appVersion
        self.role = role
    }
}

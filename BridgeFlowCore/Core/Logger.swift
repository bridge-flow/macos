import Foundation
import OSLog

public struct AppLogEntry: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let date: Date
    public let level: Level
    public let message: String

    public enum Level: String, Codable, Sendable {
        case info
        case warning
        case error
    }

    public init(id: UUID = UUID(), date: Date = Date(), level: Level, message: String) {
        self.id = id
        self.date = date
        self.level = level
        self.message = message
    }
}

@MainActor
public final class BridgeLogger: ObservableObject {
    @Published public private(set) var entries: [AppLogEntry] = []

    private let logger = Logger(subsystem: "dev.bridgeflow.app", category: "BridgeFlow")
    private let maxEntries: Int

    public init(maxEntries: Int = 250) {
        self.maxEntries = maxEntries
    }

    public func info(_ message: String) {
        append(message, level: .info)
        logger.info("\(message, privacy: .public)")
    }

    public func warning(_ message: String) {
        append(message, level: .warning)
        logger.warning("\(message, privacy: .public)")
    }

    public func error(_ message: String) {
        append(message, level: .error)
        logger.error("\(message, privacy: .public)")
    }

    private func append(_ message: String, level: AppLogEntry.Level) {
        entries.insert(AppLogEntry(level: level, message: message), at: 0)
        if entries.count > maxEntries {
            entries.removeLast(entries.count - maxEntries)
        }
    }
}

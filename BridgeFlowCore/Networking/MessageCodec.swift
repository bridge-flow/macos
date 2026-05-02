import Foundation

public enum MessageCodecError: Error, LocalizedError {
    case invalidUTF8
    case emptyLine

    public var errorDescription: String? {
        switch self {
        case .invalidUTF8:
            "The message could not be decoded as UTF-8."
        case .emptyLine:
            "The message line is empty."
        }
    }
}

public enum MessageCodec {
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private static let decoder = JSONDecoder()

    public static func encode(_ message: BridgeMessage) throws -> String {
        let data = try encoder.encode(message)
        guard let json = String(data: data, encoding: .utf8) else {
            throw MessageCodecError.invalidUTF8
        }
        return json + "\n"
    }

    public static func encodeData(_ message: BridgeMessage) throws -> Data {
        guard let data = try encode(message).data(using: .utf8) else {
            throw MessageCodecError.invalidUTF8
        }
        return data
    }

    public static func decodeLine(_ line: String) throws -> BridgeMessage? {
        let trimmed = line.trimmingCharacters(in: .newlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        guard let data = trimmed.data(using: .utf8) else {
            throw MessageCodecError.invalidUTF8
        }
        return try decoder.decode(BridgeMessage.self, from: data)
    }
}

public struct MessageStreamDecoder {
    private var buffer = ""

    public init() {}

    public mutating func append(_ chunk: String) throws -> [BridgeMessage] {
        buffer += chunk

        var messages: [BridgeMessage] = []
        while let newlineRange = buffer.range(of: "\n") {
            let line = String(buffer[..<newlineRange.lowerBound])
            buffer.removeSubrange(buffer.startIndex...newlineRange.lowerBound)

            if let message = try MessageCodec.decodeLine(line) {
                messages.append(message)
            }
        }

        return messages
    }

    public mutating func append(_ data: Data) throws -> [BridgeMessage] {
        guard let chunk = String(data: data, encoding: .utf8) else {
            throw MessageCodecError.invalidUTF8
        }
        return try append(chunk)
    }
}

import Foundation

public final class PeerClient {
    public private(set) var connection: PeerConnection?

    public init() {}

    @discardableResult
    public func connect(host: String, port: UInt16) -> PeerConnection {
        let connection = PeerConnection(host: host, port: port)
        self.connection = connection
        connection.start()
        return connection
    }

    public func disconnect() {
        connection?.cancel()
        connection = nil
    }
}

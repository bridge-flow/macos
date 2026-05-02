import Foundation
import Network

public final class PeerConnection: Identifiable {
    public let id = UUID()
    public let connection: NWConnection
    public let endpointDescription: String

    public var onMessage: ((BridgeMessage, PeerConnection) -> Void)?
    public var onStateChange: ((NWConnection.State, PeerConnection) -> Void)?
    public var onError: ((Error, PeerConnection) -> Void)?

    private let queue: DispatchQueue
    private var decoder = MessageStreamDecoder()

    public init(host: String, port: UInt16, queue: DispatchQueue? = nil) {
        let nwPort = NWEndpoint.Port(rawValue: port) ?? 48_765
        self.connection = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: .tcp)
        self.endpointDescription = "\(host):\(port)"
        self.queue = queue ?? DispatchQueue(label: "bridgeflow.peer.connection.\(UUID().uuidString)")
    }

    public init(connection: NWConnection, queue: DispatchQueue? = nil) {
        self.connection = connection
        self.endpointDescription = String(describing: connection.endpoint)
        self.queue = queue ?? DispatchQueue(label: "bridgeflow.peer.connection.\(UUID().uuidString)")
    }

    public func start() {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else {
                return
            }
            self.onStateChange?(state, self)
            if case let .failed(error) = state {
                self.onError?(error, self)
            }
        }

        receiveNext()
        connection.start(queue: queue)
    }

    public func send(_ message: BridgeMessage) {
        do {
            let data = try MessageCodec.encodeData(message)
            connection.send(content: data, completion: .contentProcessed { [weak self] error in
                guard let self, let error else {
                    return
                }
                self.onError?(error, self)
            })
        } catch {
            onError?(error, self)
        }
    }

    public func cancel() {
        connection.cancel()
    }

    private func receiveNext() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1_024) { [weak self] data, _, isComplete, error in
            guard let self else {
                return
            }

            if let data, !data.isEmpty {
                do {
                    for message in try self.decoder.append(data) {
                        self.onMessage?(message, self)
                    }
                } catch {
                    self.onError?(error, self)
                }
            }

            if let error {
                self.onError?(error, self)
                return
            }

            if !isComplete {
                self.receiveNext()
            }
        }
    }
}

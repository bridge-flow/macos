import Foundation
import Network

public final class PeerServer {
    public var onConnection: ((PeerConnection) -> Void)?
    public var onStateChange: ((NWListener.State) -> Void)?
    public var onError: ((Error) -> Void)?

    private let port: UInt16
    private let queue: DispatchQueue
    private var listener: NWListener?

    public private(set) var isRunning = false

    public init(port: UInt16 = 48_765, queue: DispatchQueue = DispatchQueue(label: "bridgeflow.peer.server")) {
        self.port = port
        self.queue = queue
    }

    public func start() throws {
        guard !isRunning else {
            return
        }

        let nwPort = NWEndpoint.Port(rawValue: port) ?? 48_765
        let listener = try NWListener(using: .tcp, on: nwPort)
        listener.service = nil

        listener.stateUpdateHandler = { [weak self] state in
            self?.onStateChange?(state)
            if case let .failed(error) = state {
                self?.onError?(error)
            }
        }

        listener.newConnectionHandler = { [weak self] nwConnection in
            guard let self else {
                return
            }
            let peerConnection = PeerConnection(connection: nwConnection)
            self.onConnection?(peerConnection)
            peerConnection.start()
        }

        self.listener = listener
        listener.start(queue: queue)
        isRunning = true
    }

    public func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }
}

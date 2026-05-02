import Foundation

public protocol PairingStore: AnyObject {
    func trustedPeerIDs() -> Set<UUID>
    func setTrustedPeerIDs(_ ids: Set<UUID>)
}

public final class InMemoryPairingStore: PairingStore {
    private var ids: Set<UUID>

    public init(ids: Set<UUID> = []) {
        self.ids = ids
    }

    public func trustedPeerIDs() -> Set<UUID> {
        ids
    }

    public func setTrustedPeerIDs(_ ids: Set<UUID>) {
        self.ids = ids
    }
}

public final class UserDefaultsPairingStore: PairingStore {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "bridgeflow.trustedPeerIDs") {
        self.defaults = defaults
        self.key = key
    }

    public func trustedPeerIDs() -> Set<UUID> {
        let values = defaults.stringArray(forKey: key) ?? []
        return Set(values.compactMap(UUID.init(uuidString:)))
    }

    public func setTrustedPeerIDs(_ ids: Set<UUID>) {
        defaults.set(ids.map(\.uuidString).sorted(), forKey: key)
    }
}

public struct PairingManager {
    private let store: PairingStore
    private let codeProvider: () -> String

    public init(store: PairingStore = UserDefaultsPairingStore(), codeProvider: @escaping () -> String = PairingManager.generateCode) {
        self.store = store
        self.codeProvider = codeProvider
    }

    public var currentCode: String {
        codeProvider()
    }

    public mutating func approve(peerID: UUID, code: String) -> Bool {
        guard code == currentCode else {
            return false
        }

        var ids = store.trustedPeerIDs()
        ids.insert(peerID)
        store.setTrustedPeerIDs(ids)
        return true
    }

    public func trust(peerID: UUID) {
        var ids = store.trustedPeerIDs()
        ids.insert(peerID)
        store.setTrustedPeerIDs(ids)
    }

    public func remove(peerID: UUID) {
        var ids = store.trustedPeerIDs()
        ids.remove(peerID)
        store.setTrustedPeerIDs(ids)
    }

    public func isTrusted(_ peerID: UUID) -> Bool {
        store.trustedPeerIDs().contains(peerID)
    }

    public static func generateCode() -> String {
        String(format: "%06d", Int.random(in: 0...999_999))
    }
}

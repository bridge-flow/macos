import Foundation

public struct MachinePlacement: Codable, Hashable, Identifiable, Sendable {
    public var peerID: UUID
    public var name: String
    public var x: Double
    public var y: Double

    public var id: UUID { peerID }

    public init(peerID: UUID, name: String, x: Double, y: Double) {
        self.peerID = peerID
        self.name = name
        self.x = x
        self.y = y
    }
}

public struct MachineLayoutSnapshot: Codable, Hashable, Sendable {
    public var originPeerID: UUID
    public var placements: [MachinePlacement]

    public init(originPeerID: UUID, placements: [MachinePlacement]) {
        self.originPeerID = originPeerID
        self.placements = placements
    }

    public func placement(for peerID: UUID) -> MachinePlacement? {
        placements.first { $0.peerID == peerID }
    }

    public func translated(relativeTo peerID: UUID) -> MachineLayoutSnapshot {
        guard let anchor = placement(for: peerID) else {
            return self
        }

        return MachineLayoutSnapshot(
            originPeerID: peerID,
            placements: placements.map { placement in
                MachinePlacement(
                    peerID: placement.peerID,
                    name: placement.name,
                    x: placement.x - anchor.x,
                    y: placement.y - anchor.y
                )
            }
        )
    }

    public func edge(from originPeerID: UUID, to targetPeerID: UUID) -> ScreenEdge? {
        guard let origin = placement(for: originPeerID),
              let target = placement(for: targetPeerID) else {
            return nil
        }

        let dx = target.x - origin.x
        let dy = target.y - origin.y

        guard abs(dx) > 0 || abs(dy) > 0 else {
            return nil
        }

        if abs(dx) >= abs(dy) {
            return dx < 0 ? .left : .right
        }

        return dy < 0 ? .below : .above
    }

    public func updating(_ placement: MachinePlacement) -> MachineLayoutSnapshot {
        var updated = placements.filter { $0.peerID != placement.peerID }
        updated.append(placement)
        return MachineLayoutSnapshot(
            originPeerID: originPeerID,
            placements: updated.sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        )
    }
}

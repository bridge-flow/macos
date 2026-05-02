import CoreGraphics
import Foundation

public enum ScreenEdge: String, Codable, CaseIterable, Identifiable, Sendable {
    case left
    case right
    case above
    case below

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .left:
            "Left"
        case .right:
            "Right"
        case .above:
            "Above"
        case .below:
            "Below"
        }
    }

    public var compactPlacementLabel: String {
        switch self {
        case .left:
            "Remote left"
        case .right:
            "Remote right"
        case .above:
            "Remote above"
        case .below:
            "Remote below"
        }
    }

    public var placementDescription: String {
        switch self {
        case .left:
            "Remote Mac is to the left of this Mac"
        case .right:
            "Remote Mac is to the right of this Mac"
        case .above:
            "Remote Mac is above this Mac"
        case .below:
            "Remote Mac is below this Mac"
        }
    }

    public var activationInstruction: String {
        switch self {
        case .left:
            "Move the pointer to the left edge of this Mac to switch"
        case .right:
            "Move the pointer to the right edge of this Mac to switch"
        case .above:
            "Move the pointer to the top edge of this Mac to switch"
        case .below:
            "Move the pointer to the bottom edge of this Mac to switch"
        }
    }

    public var arrowSystemImage: String {
        switch self {
        case .left:
            "arrow.left"
        case .right:
            "arrow.right"
        case .above:
            "arrow.up"
        case .below:
            "arrow.down"
        }
    }
}

public enum EdgeSwitchAction: Hashable, Sendable {
    case switchToPeer(edge: ScreenEdge)
    case switchToLocal
}

public struct MouseEdgeConfiguration: Codable, Hashable, Sendable {
    public var remotePosition: ScreenEdge
    public var activationDelayMs: Int
    public var activationDistancePx: Double

    public init(remotePosition: ScreenEdge = .right, activationDelayMs: Int = 250, activationDistancePx: Double = 6) {
        self.remotePosition = remotePosition
        self.activationDelayMs = activationDelayMs
        self.activationDistancePx = activationDistancePx
    }
}

public struct MouseEdgeDetector {
    public var configuration: MouseEdgeConfiguration
    private var armedEdge: ScreenEdge?
    private var armedAt: TimeInterval?

    public init(configuration: MouseEdgeConfiguration = .init()) {
        self.configuration = configuration
    }

    public mutating func evaluateLocalCursor(
        position: CGPoint,
        delta: CGVector,
        screenSize: CGSize,
        timestamp: TimeInterval
    ) -> EdgeSwitchAction? {
        let edge = configuration.remotePosition
        guard isAt(edge: edge, position: position, screenSize: screenSize),
              isMovingToward(edge: edge, delta: delta) else {
            reset()
            return nil
        }

        if armedEdge != edge {
            armedEdge = edge
            armedAt = timestamp
            return nil
        }

        guard let armedAt else {
            self.armedAt = timestamp
            return nil
        }

        let delay = Double(configuration.activationDelayMs) / 1_000
        guard timestamp - armedAt >= delay else {
            return nil
        }

        reset()
        return .switchToPeer(edge: edge)
    }

    public mutating func evaluateRemoteExit(edge: ScreenEdge) -> EdgeSwitchAction? {
        guard edge == opposite(of: configuration.remotePosition) else {
            return nil
        }
        reset()
        return .switchToLocal
    }

    public mutating func cancel() {
        reset()
    }

    private mutating func reset() {
        armedEdge = nil
        armedAt = nil
    }

    private func isAt(edge: ScreenEdge, position: CGPoint, screenSize: CGSize) -> Bool {
        let distance = configuration.activationDistancePx
        switch edge {
        case .left:
            return position.x <= distance
        case .right:
            return position.x >= screenSize.width - distance
        case .above:
            return position.y >= screenSize.height - distance
        case .below:
            return position.y <= distance
        }
    }

    private func isMovingToward(edge: ScreenEdge, delta: CGVector) -> Bool {
        switch edge {
        case .left:
            return delta.dx < 0
        case .right:
            return delta.dx > 0
        case .above:
            return delta.dy > 0
        case .below:
            return delta.dy < 0
        }
    }

    private func opposite(of edge: ScreenEdge) -> ScreenEdge {
        switch edge {
        case .left:
            .right
        case .right:
            .left
        case .above:
            .below
        case .below:
            .above
        }
    }
}

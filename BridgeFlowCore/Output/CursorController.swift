import AppKit
import CoreGraphics
import Foundation

public protocol CursorControlling: AnyObject {
    func moveBy(dx: Double, dy: Double)
    func currentPosition() -> CGPoint
}

public final class CursorController: CursorControlling {
    public init() {}

    public func currentPosition() -> CGPoint {
        guard let event = CGEvent(source: nil) else {
            return NSEvent.mouseLocation
        }
        return event.location
    }

    public func moveBy(dx: Double, dy: Double) {
        let current = currentPosition()
        let target = CGPoint(x: current.x + dx, y: current.y + dy)
        CGWarpMouseCursorPosition(target)
    }
}

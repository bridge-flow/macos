import CoreGraphics
import Foundation
import Network
@testable import BridgeFlowCore

struct TestFailure: Error, CustomStringConvertible {
    let message: String

    var description: String { message }
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw TestFailure(message: message)
    }
}

func expectEqual<T: Equatable>(_ lhs: T, _ rhs: T, _ message: String) throws {
    if lhs != rhs {
        throw TestFailure(message: "\(message). Expected \(rhs), got \(lhs)")
    }
}

func require<T>(_ value: T?, _ message: String) throws -> T {
    guard let value else {
        throw TestFailure(message: message)
    }
    return value
}

func testInputEventRoundTripsThroughMessageCodec() throws {
    let event = BridgeInputEvent.keyDown(
        keyCode: 12,
        modifiers: [.command, .shift],
        timestamp: 42.25
    )
    let message = BridgeMessage.input(event)

    let encoded = try MessageCodec.encode(message)
    try expect(encoded.hasSuffix("\n"), "Encoded messages must be newline delimited")

    let decoded = try require(MessageCodec.decodeLine(encoded), "Expected a decoded message")
    try expectEqual(decoded, message, "Input message should round-trip")
}

func testCodecDecodesMultipleNewlineDelimitedMessagesFromChunks() throws {
    var stream = MessageStreamDecoder()
    let peer = PeerInfo(
        id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
        name: "Studio Mac",
        hostname: "studio.local",
        appVersion: "1.0.0",
        role: .host
    )
    let first = try MessageCodec.encode(.hello(peer: peer))
    let second = try MessageCodec.encode(.heartbeat(timestamp: 100))

    try expectEqual(try stream.append(String((first + second).prefix(12))), [], "Partial chunks should not decode")
    let decoded = try stream.append(String((first + second).dropFirst(12)))

    try expectEqual(decoded, [.hello(peer: peer), .heartbeat(timestamp: 100)], "Stream decoder should emit complete messages")
}

func testPairingManagerTrustsPeerOnlyWhenCodeMatches() throws {
    let store = InMemoryPairingStore()
    var manager = PairingManager(store: store, codeProvider: { "123456" })
    let peerID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!

    try expect(manager.approve(peerID: peerID, code: "000000") == false, "Wrong code should be rejected")
    try expect(manager.isTrusted(peerID) == false, "Rejected peer must not be trusted")

    try expect(manager.approve(peerID: peerID, code: "123456"), "Correct code should be approved")
    try expect(manager.isTrusted(peerID), "Approved peer should be trusted")
}

func testMouseEdgeDetectorSwitchesRightAfterPersistentMovementAtEdge() throws {
    var detector = MouseEdgeDetector(
        configuration: .init(remotePosition: .right, activationDelayMs: 250, activationDistancePx: 6)
    )
    let screen = CGSize(width: 1_440, height: 900)

    try expect(detector.evaluateLocalCursor(
        position: CGPoint(x: 1_438, y: 400),
        delta: CGVector(dx: 2, dy: 0),
        screenSize: screen,
        timestamp: 10
    ) == nil, "First edge contact should arm but not switch")
    try expectEqual(detector.evaluateLocalCursor(
        position: CGPoint(x: 1_439, y: 400),
        delta: CGVector(dx: 3, dy: 0),
        screenSize: screen,
        timestamp: 10.3
    ), .switchToPeer(edge: .right), "Persistent right-edge movement should switch to peer")
}

func testMouseEdgeDetectorCancelsWhenMovementLeavesEdge() throws {
    var detector = MouseEdgeDetector(
        configuration: .init(remotePosition: .left, activationDelayMs: 250, activationDistancePx: 6)
    )
    let screen = CGSize(width: 1_440, height: 900)

    try expect(detector.evaluateLocalCursor(
        position: CGPoint(x: 3, y: 400),
        delta: CGVector(dx: -2, dy: 0),
        screenSize: screen,
        timestamp: 10
    ) == nil, "First edge contact should arm")
    try expect(detector.evaluateLocalCursor(
        position: CGPoint(x: 30, y: 400),
        delta: CGVector(dx: 4, dy: 0),
        screenSize: screen,
        timestamp: 10.4
    ) == nil, "Leaving the edge should cancel switching")
}

func testScreenEdgeDescribesRemotePlacementAndSwitchInstruction() throws {
    try expectEqual(ScreenEdge.right.placementDescription, "Remote Mac is to the right of this Mac", "Right edge placement text should be explicit")
    try expectEqual(ScreenEdge.right.activationInstruction, "Move the pointer to the right edge of this Mac to switch", "Right edge instruction should tell the user where to move")
    try expectEqual(ScreenEdge.above.compactPlacementLabel, "Remote above", "Above edge should have a compact label")
}

func testModifierStateTrackerReleasesTrackedKeysAndModifiers() throws {
    var tracker = ModifierStateTracker()

    tracker.record(.keyDown(keyCode: 12, modifiers: [.command], timestamp: 1))
    tracker.record(.flagsChanged(modifiers: [.command, .option], timestamp: 2))

    let releases = tracker.releaseAll(timestamp: 3)

    try expectEqual(Set(releases), [
        .keyUp(keyCode: 12, modifiers: [], timestamp: 3),
        .flagsChanged(modifiers: [], timestamp: 3)
    ], "Tracker should emit releases for active keys and modifiers")
    try expect(tracker.activeKeyCodes.isEmpty, "Active keys should be cleared")
    try expectEqual(tracker.activeModifiers, [], "Active modifiers should be cleared")
}

func testEventNormalizerBuildsKeyDownFromCGEvent() throws {
    let event = try require(
        CGEvent(keyboardEventSource: nil, virtualKey: 53, keyDown: true),
        "Expected synthetic key event"
    )
    event.flags = [.maskCommand, .maskShift]

    let normalised = EventNormalizer.normalise(event: event, type: .keyDown, timestamp: 12)

    try expectEqual(
        normalised,
        .keyDown(keyCode: 53, modifiers: [.command, .shift], timestamp: 12),
        "Key events should preserve key code and modifiers"
    )
}

func testEventNormalizerBuildsMouseMoveDeltaFromCGEvent() throws {
    let event = try require(
        CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: CGPoint(x: 100, y: 100),
            mouseButton: .left
        ),
        "Expected synthetic mouse event"
    )
    event.setDoubleValueField(.mouseEventDeltaX, value: 4)
    event.setDoubleValueField(.mouseEventDeltaY, value: -7)

    let normalised = EventNormalizer.normalise(event: event, type: .mouseMoved, timestamp: 20)

    try expectEqual(
        normalised,
        .mouseMove(dx: 4, dy: -7, timestamp: 20),
        "Mouse move events should use CoreGraphics deltas"
    )
}

func testDiscoveredPeerParsesBonjourTXTRecord() throws {
    let peer = PeerInfo(
        id: UUID(uuidString: "99999999-AAAA-BBBB-CCCC-DDDDDDDDDDDD")!,
        name: "Studio Mac",
        hostname: "studio.local",
        appVersion: "0.1.0",
        role: .both
    )
    let endpoint = NWEndpoint.service(
        name: "Studio Mac",
        type: PeerDiscovery.serviceType,
        domain: "local",
        interface: nil
    )

    let discovered = try require(
        DiscoveredPeer(endpoint: endpoint, txtRecord: DiscoveredPeer.txtRecord(for: peer)),
        "Expected Bonjour TXT record to decode into a discovered peer"
    )

    try expectEqual(discovered.id, peer.id, "Discovered peer should keep the advertised stable id")
    try expectEqual(discovered.name, peer.name, "Discovered peer should keep the advertised name")
    try expectEqual(discovered.hostname, peer.hostname, "Discovered peer should keep hostname")
    try expectEqual(discovered.role, peer.role, "Discovered peer should keep mode")
    try expect(discovered.endpointDescription.contains("_bridgeflow._tcp"), "Endpoint should describe the BridgeFlow Bonjour service")
}

func testDiscoveredPeerFallsBackWhenBonjourTXTRecordIsMissing() throws {
    let endpoint = NWEndpoint.service(
        name: "Remote Mac",
        type: PeerDiscovery.serviceType,
        domain: "local",
        interface: nil
    )

    let first = try require(
        DiscoveredPeer(endpoint: endpoint, txtRecord: NWTXTRecord([:])),
        "Expected Bonjour endpoint without TXT to still produce a peer"
    )
    let second = try require(
        DiscoveredPeer(endpoint: endpoint, txtRecord: NWTXTRecord([:])),
        "Expected fallback id to be stable"
    )

    try expectEqual(first.id, second.id, "Fallback peer id should be deterministic")
    try expectEqual(first.name, "Remote Mac", "Fallback peer should use service name")
    try expect(first.hasStableID == false, "Fallback peer should be marked as temporary")
}

let tests: [(String, () throws -> Void)] = [
    ("input event codec round-trip", testInputEventRoundTripsThroughMessageCodec),
    ("stream decoder chunking", testCodecDecodesMultipleNewlineDelimitedMessagesFromChunks),
    ("pairing code trust", testPairingManagerTrustsPeerOnlyWhenCodeMatches),
    ("right edge switching", testMouseEdgeDetectorSwitchesRightAfterPersistentMovementAtEdge),
    ("edge cancellation", testMouseEdgeDetectorCancelsWhenMovementLeavesEdge),
    ("screen edge copy", testScreenEdgeDescribesRemotePlacementAndSwitchInstruction),
    ("modifier release tracking", testModifierStateTrackerReleasesTrackedKeysAndModifiers),
    ("key event normalisation", testEventNormalizerBuildsKeyDownFromCGEvent),
    ("mouse movement normalisation", testEventNormalizerBuildsMouseMoveDeltaFromCGEvent),
    ("bonjour discovery metadata", testDiscoveredPeerParsesBonjourTXTRecord),
    ("bonjour discovery fallback", testDiscoveredPeerFallsBackWhenBonjourTXTRecordIsMissing)
]

var failures: [String] = []

for (name, test) in tests {
    do {
        try test()
        print("PASS \(name)")
    } catch {
        failures.append("FAIL \(name): \(error)")
    }
}

if failures.isEmpty {
    print("All \(tests.count) BridgeFlowCore tests passed")
} else {
    failures.forEach { print($0) }
    exit(1)
}

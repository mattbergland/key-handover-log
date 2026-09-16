@testable import KeyHandoverLog
import Foundation
import XCTest

final class KeyLogStoreTests: XCTestCase {
    private var fileURL: URL!
    private var sam: Volunteer!
    private var priya: Volunteer!
    private var key: LighthouseKey!
    private var store: LocalKeyLogStore!

    override func setUpWithError() throws {
        fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("keylog.json")
        sam = Volunteer(id: UUID(), name: "Sam", initials: "S", role: "Keeper", phone: nil)
        priya = Volunteer(id: UUID(), name: "Priya", initials: "P", role: "Keeper", phone: nil)
        key = LighthouseKey(id: UUID(), name: "Test key", colorName: "teal", description: "", holderId: sam.id, dueBackAt: nil)
        store = LocalKeyLogStore(fileURL: fileURL) {
            KeyLogSnapshot(volunteers: [self.sam, self.priya], keys: [self.key], handovers: [], currentUserId: self.sam.id)
        }
        try store.load()
    }

    func testHandoverCreatesPendingAndLeavesHolder() throws {
        let handover = try store.handOver(keyId: key.id, to: priya.id, dueBackAt: nil, note: "Hi", now: .now)
        XCTAssertEqual(handover.status, .pending)
        XCTAssertEqual(store.key(id: key.id)?.holderId, sam.id)
    }

    func testConfirmUpdatesHolderAndDueDate() throws {
        let due = Date().addingTimeInterval(1000)
        let handover = try store.handOver(keyId: key.id, to: priya.id, dueBackAt: due, note: nil, now: .now)
        try store.confirmReceipt(handoverId: handover.id, now: .now)
        XCTAssertEqual(store.key(id: key.id)?.holderId, priya.id)
        XCTAssertEqual(store.key(id: key.id)?.dueBackAt, due)
        XCTAssertEqual(store.handovers.first?.status, .confirmed)
    }

    func testDeclineRemovesPending() throws {
        let handover = try store.handOver(keyId: key.id, to: priya.id, dueBackAt: nil, note: nil, now: .now)
        try store.declineHandover(handoverId: handover.id)
        XCTAssertTrue(store.handovers.isEmpty)
    }

    func testReturnClearsHolderAndRecordsEvent() throws {
        try store.returnToLockbox(keyId: key.id, note: "Done", now: .now)
        XCTAssertNil(store.key(id: key.id)?.holderId)
        XCTAssertNil(store.key(id: key.id)?.dueBackAt)
        XCTAssertEqual(store.handovers.first?.status, .returnedToLockbox)
    }

    func testOverdueOnlyAppliesToHeldKeys() {
        let past = Date().addingTimeInterval(-10)
        XCTAssertFalse(key.isOverdue(now: .now))
        var overdue = key!
        overdue.dueBackAt = past
        XCTAssertTrue(overdue.isOverdue(now: .now))
        overdue.holderId = nil
        XCTAssertFalse(overdue.isOverdue(now: .now))
    }

    func testPersistenceRoundTrip() throws {
        _ = try store.handOver(keyId: key.id, to: priya.id, dueBackAt: nil, note: nil, now: .now)
        let reloaded = LocalKeyLogStore(fileURL: fileURL)
        try reloaded.load()
        XCTAssertEqual(reloaded.handovers.count, 1)
        XCTAssertEqual(reloaded.keys, store.keys)
    }

    func testHandoverToCurrentHolderThrows() {
        XCTAssertThrowsError(try store.handOver(keyId: key.id, to: sam.id, dueBackAt: nil, note: nil, now: .now)) { error in
            XCTAssertEqual(error as? KeyLogStoreError, .invalidState("Choose someone other than the current key holder."))
        }
    }
}

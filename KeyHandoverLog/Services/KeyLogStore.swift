import Foundation
import Observation

enum KeyLogStoreError: LocalizedError, Equatable {
    case loadFailed(String)
    case saveFailed(String)
    case notFound
    case invalidState(String)

    var errorDescription: String? {
        switch self {
        case .loadFailed(let message): "Could not load your key log. \(message)"
        case .saveFailed(let message): "Could not save your key log. \(message)"
        case .notFound: "That handover or key could not be found."
        case .invalidState(let message): message
        }
    }
}

protocol KeyLogStore: AnyObject, Observable {
    var volunteers: [Volunteer] { get }
    var keys: [LighthouseKey] { get }
    var handovers: [Handover] { get }
    var currentUserId: UUID? { get }
    var lastError: KeyLogStoreError? { get set }
    func load() throws
    func setCurrentUser(_ id: UUID)
    @discardableResult func handOver(keyId: UUID, to volunteerId: UUID, dueBackAt: Date?, note: String?, now: Date) throws -> Handover
    func confirmReceipt(handoverId: UUID, now: Date) throws
    func declineHandover(handoverId: UUID) throws
    func returnToLockbox(keyId: UUID, note: String?, now: Date) throws
    func resetDemoData() throws
}

extension KeyLogStore {
    func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            lastError = error as? KeyLogStoreError
        }
    }

    func handOver(keyId: UUID, to volunteerId: UUID, dueBackAt: Date?, note: String?) throws -> Handover {
        try handOver(keyId: keyId, to: volunteerId, dueBackAt: dueBackAt, note: note, now: .now)
    }

    func confirmReceipt(handoverId: UUID) throws { try confirmReceipt(handoverId: handoverId, now: .now) }

    func returnToLockbox(keyId: UUID, note: String?) throws {
        try returnToLockbox(keyId: keyId, note: note, now: .now)
    }

    func volunteer(id: UUID?) -> Volunteer? {
        guard let id else { return nil }
        return volunteers.first { $0.id == id }
    }

    func key(id: UUID) -> LighthouseKey? { keys.first { $0.id == id } }

    func handovers(forKey keyId: UUID) -> [Handover] {
        handovers.filter { $0.keyId == keyId }.sorted { $0.createdAt > $1.createdAt }
    }

    func pendingHandover(forKey keyId: UUID) -> Handover? {
        handovers.first { $0.keyId == keyId && $0.status == .pending }
    }

    func pendingHandovers(forUser userId: UUID? = nil) -> [Handover] {
        let id = userId ?? currentUserId
        return handovers.filter { $0.status == .pending && $0.toVolunteerId == id }
    }

    func keysHeld(by volunteerId: UUID) -> [LighthouseKey] {
        keys.filter { $0.holderId == volunteerId }
    }

    func overdueKeys(now: Date = .now) -> [LighthouseKey] {
        keys.filter { $0.isOverdue(now: now) }
    }

    var currentUser: Volunteer? { volunteer(id: currentUserId) }
}

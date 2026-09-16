import Foundation
import Observation

@Observable
final class LocalKeyLogStore: KeyLogStore {
    var volunteers: [Volunteer] = []
    var keys: [LighthouseKey] = []
    var handovers: [Handover] = []
    var currentUserId: UUID?
    var lastError: KeyLogStoreError?

    private let fileURL: URL
    private let seed: () -> KeyLogSnapshot

    init(fileURL: URL? = nil, seed: @escaping () -> KeyLogSnapshot = { SampleData.snapshot() }) {
        self.fileURL = fileURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("keylog.json")
        self.seed = seed
    }

    func load() throws {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                let snapshot = try decoder.decode(KeyLogSnapshot.self, from: data)
                apply(snapshot)
            } else {
                apply(seed())
                try save()
            }
        } catch let error as KeyLogStoreError {
            throw error
        } catch {
            throw KeyLogStoreError.loadFailed(error.localizedDescription)
        }
    }

    func setCurrentUser(_ id: UUID) {
        currentUserId = id
        do { try save() } catch { lastError = error as? KeyLogStoreError }
    }

    @discardableResult
    func handOver(keyId: UUID, to volunteerId: UUID, dueBackAt: Date?, note: String?, now: Date) throws -> Handover {
        guard let keyIndex = keys.firstIndex(where: { $0.id == keyId }),
              volunteers.contains(where: { $0.id == volunteerId }) else { throw KeyLogStoreError.notFound }
        let key = keys[keyIndex]
        guard key.holderId != volunteerId else {
            throw KeyLogStoreError.invalidState("Choose someone other than the current key holder.")
        }
        guard pendingHandover(forKey: keyId) == nil else {
            throw KeyLogStoreError.invalidState("This key already has a handover awaiting confirmation.")
        }
        let handover = Handover(id: UUID(), keyId: keyId, fromVolunteerId: key.holderId, toVolunteerId: volunteerId,
                                createdAt: now, dueBackAt: dueBackAt, status: .pending, confirmedAt: nil, note: note)
        handovers.append(handover)
        try save()
        return handover
    }

    func confirmReceipt(handoverId: UUID, now: Date) throws {
        guard let index = handovers.firstIndex(where: { $0.id == handoverId }),
              handovers[index].status == .pending else { throw KeyLogStoreError.notFound }
        let handover = handovers[index]
        guard let keyIndex = keys.firstIndex(where: { $0.id == handover.keyId }) else { throw KeyLogStoreError.notFound }
        handovers[index].status = .confirmed
        handovers[index].confirmedAt = now
        keys[keyIndex].holderId = handover.toVolunteerId
        keys[keyIndex].dueBackAt = handover.dueBackAt
        try save()
    }

    func declineHandover(handoverId: UUID) throws {
        guard let index = handovers.firstIndex(where: { $0.id == handoverId }),
              handovers[index].status == .pending else { throw KeyLogStoreError.notFound }
        handovers.remove(at: index)
        try save()
    }

    func returnToLockbox(keyId: UUID, note: String?, now: Date) throws {
        guard let keyIndex = keys.firstIndex(where: { $0.id == keyId }) else { throw KeyLogStoreError.notFound }
        let key = keys[keyIndex]
        handovers.removeAll { $0.keyId == keyId && $0.status == .pending }
        handovers.append(Handover(id: UUID(), keyId: keyId, fromVolunteerId: key.holderId, toVolunteerId: nil,
                                  createdAt: now, dueBackAt: nil, status: .returnedToLockbox,
                                  confirmedAt: now, note: note))
        keys[keyIndex].holderId = nil
        keys[keyIndex].dueBackAt = nil
        try save()
    }

    func resetDemoData() throws {
        apply(seed())
        try save()
    }

    private func apply(_ snapshot: KeyLogSnapshot) {
        volunteers = snapshot.volunteers
        keys = snapshot.keys
        handovers = snapshot.handovers
        currentUserId = snapshot.currentUserId
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private var decoder: JSONDecoder { Self.decoder }

    private func save() throws {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(KeyLogSnapshot(volunteers: volunteers, keys: keys, handovers: handovers, currentUserId: currentUserId))
                .write(to: fileURL, options: .atomic)
        } catch {
            throw KeyLogStoreError.saveFailed(error.localizedDescription)
        }
    }
}

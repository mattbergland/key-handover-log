import Foundation

enum SampleData {
    static func snapshot(now: Date = .now) -> KeyLogSnapshot {
        let sam = Volunteer(id: UUID(), name: "Sam Okafor", initials: "SO", role: "Coordinator", phone: "07123 456 789")
        let priya = Volunteer(id: UUID(), name: "Priya Nair", initials: "PN", role: "Keeper", phone: "07123 555 102")
        let tom = Volunteer(id: UUID(), name: "Tom Whitlock", initials: "TW", role: "Keeper", phone: "07123 555 203")
        let ailsa = Volunteer(id: UUID(), name: "Ailsa McRae", initials: "AM", role: "Keeper", phone: nil)
        let dev = Volunteer(id: UUID(), name: "Dev Patel", initials: "DP", role: "Trainee Keeper", phone: "07123 555 405")
        let volunteers = [sam, priya, tom, ailsa, dev]
        let lamp = LighthouseKey(id: UUID(), name: "Lamp Room", colorName: "yellow", description: "Access to the main lamp room and service balcony.", holderId: priya.id, dueBackAt: now.addingTimeInterval(-3600))
        let gate = LighthouseKey(id: UUID(), name: "Gate Padlock", colorName: "blue", description: "Main grounds gate padlock and chain.", holderId: tom.id, dueBackAt: now.addingTimeInterval(8 * 3600))
        let oil = LighthouseKey(id: UUID(), name: "Oil Store", colorName: "orange", description: "Oil store and maintenance shed access.", holderId: ailsa.id, dueBackAt: now.addingTimeInterval(-2 * 3600))
        let visitor = LighthouseKey(id: UUID(), name: "Visitor Centre", colorName: "green", description: "Visitor centre, office and till cupboard.", holderId: sam.id, dueBackAt: now.addingTimeInterval(24 * 3600))
        let master = LighthouseKey(id: UUID(), name: "Lockbox Master", colorName: "purple", description: "Master key for the secure key cabinet.", holderId: nil, dueBackAt: nil)
        let fog = LighthouseKey(id: UUID(), name: "Fog Signal House", colorName: "teal", description: "Fog signal house and generator room.", holderId: nil, dueBackAt: nil)
        let keys = [lamp, gate, oil, visitor, master, fog]
        func handover(_ key: LighthouseKey, _ from: UUID?, _ to: UUID?, _ days: Double, _ status: HandoverStatus = .confirmed, _ due: Date? = nil, _ note: String? = nil) -> Handover {
            Handover(id: UUID(), keyId: key.id, fromVolunteerId: from, toVolunteerId: to, createdAt: now.addingTimeInterval(days * 86400),
                     dueBackAt: due, status: status, confirmedAt: status == .pending ? nil : now.addingTimeInterval(days * 86400 + 300), note: note)
        }
        var handovers: [Handover] = []
        for (index, key) in keys.enumerated() {
            handovers.append(handover(key, nil, sam.id, -21, .confirmed, now.addingTimeInterval(-18 * 86400)))
            handovers.append(handover(key, sam.id, [priya.id, tom.id, ailsa.id, sam.id, nil, nil][index], -14, .confirmed, key.dueBackAt))
            handovers.append(handover(key, key.holderId, key.holderId, -7, .confirmed, key.dueBackAt))
        }
        if let index = handovers.firstIndex(where: { $0.keyId == lamp.id && $0.toVolunteerId == priya.id }) {
            handovers[index].note = "Evening lamp check"
        }
        handovers.append(Handover(id: UUID(), keyId: lamp.id, fromVolunteerId: priya.id, toVolunteerId: sam.id,
                                  createdAt: now.addingTimeInterval(-1800), dueBackAt: now.addingTimeInterval(4 * 3600),
                                  status: .pending, confirmedAt: nil, note: "Please take the morning watch."))
        return KeyLogSnapshot(volunteers: volunteers, keys: keys, handovers: handovers, currentUserId: sam.id)
    }
}

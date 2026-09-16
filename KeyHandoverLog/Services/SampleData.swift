import Foundation

enum SampleData {
    private struct Context {
        let lamp: LighthouseKey
        let gate: LighthouseKey
        let oil: LighthouseKey
        let visitor: LighthouseKey
        let master: LighthouseKey
        let fog: LighthouseKey
        let sam: Volunteer
        let priya: Volunteer
        let tom: Volunteer
        let ailsa: Volunteer
        let dev: Volunteer
    }

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
        let context = Context(
            lamp: lamp,
            gate: gate,
            oil: oil,
            visitor: visitor,
            master: master,
            fog: fog,
            sam: sam,
            priya: priya,
            tom: tom,
            ailsa: ailsa,
            dev: dev
        )
        let handovers = Self.handovers(now: now, context: context)
        return KeyLogSnapshot(volunteers: volunteers, keys: keys, handovers: handovers, currentUserId: sam.id)
    }

    private static func handovers(now: Date, context: Context) -> [Handover] {
        func days(_ d: Double, hour: Int) -> Date {
            Calendar.current.date(
                bySettingHour: hour,
                minute: 30,
                second: 0,
                of: now.addingTimeInterval(d * 86400)
            ) ?? now.addingTimeInterval(d * 86400)
        }

        func makeHandover(
            _ key: LighthouseKey,
            from: UUID?,
            to: UUID?,
            createdAt: Date,
            dueBackAt: Date?,
            status: HandoverStatus = .confirmed,
            note: String? = nil
        ) -> Handover {
            Handover(
                id: UUID(),
                keyId: key.id,
                fromVolunteerId: from,
                toVolunteerId: to,
                createdAt: createdAt,
                dueBackAt: dueBackAt,
                status: status,
                confirmedAt: status == .pending ? nil : createdAt.addingTimeInterval(15 * 60),
                note: note
            )
        }

        return [
            makeHandover(context.lamp, from: nil, to: context.sam.id, createdAt: days(-20, hour: 8), dueBackAt: days(-18, hour: 18)),
            makeHandover(context.lamp, from: context.sam.id, to: context.priya.id, createdAt: days(-15, hour: 19), dueBackAt: days(-14, hour: 23), note: "Evening lamp check"),
            makeHandover(context.lamp, from: context.priya.id, to: context.sam.id, createdAt: days(-7, hour: 7), dueBackAt: days(-6, hour: 18)),
            makeHandover(context.lamp, from: context.sam.id, to: context.priya.id, createdAt: days(-3, hour: 16), dueBackAt: context.lamp.dueBackAt),
            makeHandover(context.lamp, from: context.priya.id, to: context.sam.id, createdAt: days(-1, hour: 17), dueBackAt: now.addingTimeInterval(4 * 3600), status: .pending, note: "Please take the morning watch."),

            makeHandover(context.gate, from: nil, to: context.tom.id, createdAt: days(-19, hour: 9), dueBackAt: days(-16, hour: 17)),
            makeHandover(context.gate, from: context.tom.id, to: context.ailsa.id, createdAt: days(-12, hour: 13), dueBackAt: days(-9, hour: 18), note: "Gate chain replaced"),
            makeHandover(context.gate, from: context.ailsa.id, to: context.tom.id, createdAt: days(-6, hour: 11), dueBackAt: context.gate.dueBackAt),

            makeHandover(context.oil, from: nil, to: context.dev.id, createdAt: days(-17, hour: 10), dueBackAt: days(-14, hour: 16)),
            makeHandover(context.oil, from: context.dev.id, to: context.ailsa.id, createdAt: days(-10, hour: 15), dueBackAt: context.oil.dueBackAt, note: "Spare lantern collected"),

            makeHandover(context.visitor, from: nil, to: context.sam.id, createdAt: days(-20, hour: 8), dueBackAt: days(-17, hour: 17)),
            makeHandover(context.visitor, from: context.sam.id, to: context.tom.id, createdAt: days(-9, hour: 12), dueBackAt: days(-6, hour: 18)),
            makeHandover(context.visitor, from: context.tom.id, to: context.sam.id, createdAt: days(-4, hour: 14), dueBackAt: context.visitor.dueBackAt, note: "Tour group Saturday"),

            makeHandover(context.master, from: nil, to: context.sam.id, createdAt: days(-18, hour: 9), dueBackAt: days(-15, hour: 17)),
            makeHandover(context.master, from: context.sam.id, to: nil, createdAt: days(-6, hour: 18), dueBackAt: nil, note: "Key cabinet audit"),

            makeHandover(context.fog, from: nil, to: context.priya.id, createdAt: days(-15, hour: 7), dueBackAt: days(-12, hour: 16)),
            makeHandover(context.fog, from: context.priya.id, to: nil, createdAt: days(-2, hour: 20), dueBackAt: nil, note: "Fog signal test complete")
        ]
    }
}

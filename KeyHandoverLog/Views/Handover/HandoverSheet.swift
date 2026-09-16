import SwiftUI

struct HandoverSheet: View {
    @Environment(LocalKeyLogStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let key: LighthouseKey
    @State private var recipientId: UUID?
    @State private var preset: DuePreset = .endOfShift
    @State private var customDate = Date().addingTimeInterval(4 * 3600)
    @State private var note = ""
    @State private var returningToLockbox = false

    enum DuePreset: String, CaseIterable, Identifiable {
        case endOfShift = "End of shift", tomorrow = "Tomorrow", threeDays = "3 days", custom = "Custom"
        var id: String { rawValue }
        var interval: TimeInterval? {
            switch self {
            case .endOfShift: 4 * 3600
            case .tomorrow: 24 * 3600
            case .threeDays: 3 * 24 * 3600
            case .custom: nil
            }
        }
    }

    private var recipients: [Volunteer] {
        store.volunteers.filter { $0.id != key.holderId }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Recipient") {
                    ForEach(recipients) { volunteer in
                        Button {
                            recipientId = volunteer.id
                            returningToLockbox = false
                        } label: {
                            HStack {
                                AvatarView(initials: volunteer.initials, name: volunteer.name, size: 30)
                                Text(volunteer.name).foregroundStyle(.primary)
                                Spacer()
                                if recipientId == volunteer.id { Image(systemName: "checkmark") }
                            }
                        }
                    }
                    if !key.isInLockbox {
                        Button {
                            recipientId = nil
                            returningToLockbox = true
                        } label: {
                            Label("Return to lockbox", systemImage: "lock.fill")
                        }
                    }
                }
                if recipientId != nil {
                    Section("Due back") {
                        Picker("Due back", selection: $preset) {
                            ForEach(DuePreset.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        if preset == .custom { DatePicker("Date", selection: $customDate, in: Date()...) }
                    }
                    Section("Note") { TextField("Optional note", text: $note, axis: .vertical) }
                }
            }
            .navigationTitle("Hand over \(key.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") { confirm() }.disabled(recipientId == nil && !returningToLockbox)
                }
            }
        }
    }

    private func confirm() {
        if returningToLockbox {
            store.perform { try store.returnToLockbox(keyId: key.id, note: note.isEmpty ? nil : note) }
            dismiss()
            return
        }
        guard let recipientId else { return }
        let due = preset.interval.map { Date().addingTimeInterval($0) } ?? customDate
        do {
            try store.handOver(keyId: key.id, to: recipientId, dueBackAt: due, note: note.isEmpty ? nil : note)
            dismiss()
        } catch {
            store.lastError = error as? KeyLogStoreError
        }
    }
}

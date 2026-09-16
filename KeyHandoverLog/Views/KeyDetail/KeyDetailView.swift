import SwiftUI

struct KeyDetailView: View {
    @Environment(LocalKeyLogStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let keyId: UUID
    @State private var showingHandover = false
    @State private var showingReturnConfirmation = false

    private var key: LighthouseKey? { store.key(id: keyId) }
    private var pending: Handover? { store.pendingHandover(forKey: keyId) }

    var body: some View {
        Group {
            if let key {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 14) {
                            KeyTagView(key: key)
                            VStack(alignment: .leading) {
                                Text(key.name).font(.largeTitle.bold())
                                Text(key.description).foregroundStyle(.secondary)
                            }
                        }
                        statusCard(key)
                        if let pending, pending.toVolunteerId == store.currentUserId {
                            HStack {
                                Image(systemName: "bell.fill")
                                Text("This handover is waiting for your confirmation.")
                            }.foregroundStyle(.orange)
                        }
                        HStack {
                            Button("Hand over") { showingHandover = true }.buttonStyle(.borderedProminent)
                            if !key.isInLockbox {
                                Button("Return to lockbox", role: .destructive) { showingReturnConfirmation = true }.buttonStyle(.bordered)
                            }
                        }
                        if let pending, pending.toVolunteerId == store.currentUserId {
                            HStack {
                                Button("Confirm receipt") { try? store.confirmReceipt(handoverId: pending.id) }.buttonStyle(.borderedProminent)
                                Button("Decline", role: .destructive) { try? store.declineHandover(handoverId: pending.id) }.buttonStyle(.bordered)
                            }
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Timeline").font(.title2.bold())
                            if store.handovers(forKey: keyId).isEmpty {
                                ContentUnavailableView("No history yet", systemImage: "clock")
                            } else {
                                ForEach(store.handovers(forKey: keyId)) { handover in
                                    HandoverTimelineRow(handover: handover)
                                }
                            }
                        }
                    }.padding()
                }
                .navigationTitle("Key details")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showingHandover) { HandoverSheet(key: key) }
                .confirmationDialog("Return this key to the lockbox?", isPresented: $showingReturnConfirmation) {
                    Button("Return to lockbox", role: .destructive) { try? store.returnToLockbox(keyId: key.id, note: nil) }
                    Button("Cancel", role: .cancel) {}
                }
            } else {
                ContentUnavailableView("Key not found", systemImage: "questionmark")
            }
        }
    }

    private func statusCard(_ key: LighthouseKey) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(key.isInLockbox ? "In lockbox" : "Out with \(displayName(key.holderId, store: store))",
                  systemImage: key.isInLockbox ? "lock.fill" : "person.fill")
            if let due = key.dueBackAt {
                HStack {
                    Text("Due back \(due, formatter: RelativeDateTimeFormatter())")
                    if key.isOverdue(now: .now) { StatusBadge(title: "Overdue") }
                }
            }
        }.padding().frame(maxWidth: .infinity, alignment: .leading).background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct HandoverTimelineRow: View {
    @Environment(LocalKeyLogStore.self) private var store
    let handover: Handover

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: handover.status == .pending ? "clock" : "checkmark.circle.fill").foregroundStyle(handover.status == .pending ? .orange : .green)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(displayName(handover.fromVolunteerId, store: store)) → \(displayName(handover.toVolunteerId, store: store))")
                Text("\(handover.createdAt, formatter: RelativeDateTimeFormatter()) · \(handover.createdAt.shortDateTime)")
                    .font(.caption).foregroundStyle(.secondary)
                Text(handover.status.rawValue.replacingOccurrences(of: "To", with: " to ").capitalized).font(.caption.weight(.semibold))
                if let note = handover.note { Text(note).font(.subheadline).foregroundStyle(.secondary) }
            }
        }.padding(.vertical, 4)
    }
}

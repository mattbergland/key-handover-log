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
                        ViewThatFits(in: .horizontal) {
                            HStack {
                                handoverButton
                                if !key.isInLockbox {
                                    returnButton
                                }
                            }
                            VStack(alignment: .leading) {
                                handoverButton
                                if !key.isInLockbox {
                                    returnButton
                                }
                            }
                        }
                        if let pending, pending.toVolunteerId == store.currentUserId {
                            ViewThatFits(in: .horizontal) {
                                HStack {
                                    confirmButton(for: pending)
                                    declineButton(for: pending)
                                }
                                VStack(alignment: .leading) {
                                    confirmButton(for: pending)
                                    declineButton(for: pending)
                                }
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
                    Button("Return to lockbox", role: .destructive) {
                        store.perform { try store.returnToLockbox(keyId: key.id, note: nil) }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            } else {
                ContentUnavailableView("Key not found", systemImage: "questionmark")
            }
        }
    }

    private var handoverButton: some View {
        Button {
            showingHandover = true
        } label: {
            Text("Hand over")
                .multilineTextAlignment(.center)
        }
        .buttonStyle(.borderedProminent)
        .fixedSize(horizontal: false, vertical: true)
        .controlSize(.large)
    }

    private var returnButton: some View {
        Button(role: .destructive) {
            showingReturnConfirmation = true
        } label: {
            Text("Return to lockbox")
                .multilineTextAlignment(.center)
        }
        .buttonStyle(.bordered)
        .fixedSize(horizontal: false, vertical: true)
        .controlSize(.large)
    }

    private func confirmButton(for pending: Handover) -> some View {
        Button {
            store.perform { try store.confirmReceipt(handoverId: pending.id) }
        } label: {
            Text("Confirm receipt")
                .multilineTextAlignment(.center)
        }
        .buttonStyle(.borderedProminent)
        .fixedSize(horizontal: false, vertical: true)
        .controlSize(.large)
    }

    private func declineButton(for pending: Handover) -> some View {
        Button(role: .destructive) {
            store.perform { try store.declineHandover(handoverId: pending.id) }
        } label: {
            Text("Decline")
                .multilineTextAlignment(.center)
        }
        .buttonStyle(.bordered)
        .fixedSize(horizontal: false, vertical: true)
        .controlSize(.large)
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

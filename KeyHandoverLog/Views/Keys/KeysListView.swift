import SwiftUI

struct KeysListView: View {
    @Environment(LocalKeyLogStore.self) private var store
    @State private var selectedKey: LighthouseKey?

    var body: some View {
        NavigationStack {
            List {
                let overdue = store.overdueKeys()
                let out = store.keys.filter { !$0.isInLockbox && !$0.isOverdue(now: .now) }
                let lockbox = store.keys.filter(\.isInLockbox)
                if !store.pendingHandovers().isEmpty {
                    Section { ForEach(store.pendingHandovers()) { PendingHandoverBanner(handover: $0) } }
                }
                if !overdue.isEmpty {
                    Section {
                        ForEach(overdue) { key in
                            KeyRowView(key: key)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedKey = key }
                        }
                    } header: {
                        Label("Overdue", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red)
                    }
                }
                if !out.isEmpty {
                    Section("Out") {
                        ForEach(out) { key in
                            KeyRowView(key: key)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedKey = key }
                        }
                    }
                }
                if !lockbox.isEmpty {
                    Section("In lockbox") {
                        ForEach(lockbox) { key in
                            KeyRowView(key: key)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedKey = key }
                        }
                    }
                }
                if store.keys.isEmpty { ContentUnavailableView("No keys yet", systemImage: "key.slash", description: Text("Add a key to start tracking handovers.")) }
            }
            .navigationTitle("Keys")
            .sheet(item: $selectedKey) { KeyDetailView(keyId: $0.id) }
        }
    }
}

struct KeyRowView: View {
    @Environment(LocalKeyLogStore.self) private var store
    let key: LighthouseKey
    private var pending: Handover? { store.pendingHandover(forKey: key.id) }

    var body: some View {
        HStack(spacing: 12) {
            KeyTagView(key: key)
            VStack(alignment: .leading, spacing: 4) {
                Text(key.name).font(.headline)
                if let pending, let recipient = store.volunteer(id: pending.toVolunteerId) {
                    Text("Handing over to \(recipient.name) — awaiting confirmation").font(.caption).foregroundStyle(.secondary)
                } else if let due = key.dueBackAt {
                    Text(due < .now ? "Overdue" : "Due back \(due, formatter: RelativeDateTimeFormatter())")
                        .font(.caption).foregroundStyle(due < .now ? .red : .secondary)
                }
            }
            Spacer()
            if let holder = store.volunteer(id: key.holderId) {
                AvatarView(initials: holder.initials, name: holder.name, size: 34)
            } else {
                Image(systemName: "lock.fill").foregroundStyle(.secondary).accessibilityLabel("In lockbox")
            }
        }
        .padding(.vertical, 4)
    }
}

struct PendingHandoverBanner: View {
    @Environment(LocalKeyLogStore.self) private var store
    let handover: Handover

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text("\(store.volunteer(id: handover.fromVolunteerId)?.name ?? "Someone") is handing you the \(store.key(id: handover.keyId)?.name ?? "key")")
            } icon: { Image(systemName: "hand.point.right.fill") }
            HStack {
                Button("Confirm") { store.perform { try store.confirmReceipt(handoverId: handover.id) } }
                    .buttonStyle(.borderedProminent)
                Button("Decline", role: .destructive) { store.perform { try store.declineHandover(handoverId: handover.id) } }
                    .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
}

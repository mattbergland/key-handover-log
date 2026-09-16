import SwiftUI

struct VolunteersView: View {
    @Environment(LocalKeyLogStore.self) private var store
    @State private var showingResetConfirmation = false
    @State private var selectedVolunteer: Volunteer?

    var body: some View {
        NavigationStack {
            List {
                Section("Acting as") {
                    Picker("Current user", selection: Binding(
                        get: { store.currentUserId ?? store.volunteers.first?.id ?? UUID() },
                        set: { store.setCurrentUser($0) }
                    )) {
                        ForEach(store.volunteers) { Text($0.name).tag($0.id) }
                    }
                }
                Section("Crew") {
                    ForEach(store.volunteers) { volunteer in
                        Button { selectedVolunteer = volunteer } label: { VolunteerRow(volunteer: volunteer) }
                            .buttonStyle(.plain)
                    }
                }
                Section {
                    Button("Reset demo data", role: .destructive) { showingResetConfirmation = true }
                } footer: {
                    Text("Demo mode stores this log only on this device.")
                }
            }
            .navigationTitle("Volunteers")
            .sheet(item: $selectedVolunteer) { VolunteerDetailView(volunteerId: $0.id) }
            .confirmationDialog("Reset all demo data?", isPresented: $showingResetConfirmation) {
                Button("Reset demo data", role: .destructive) { try? store.resetDemoData() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

struct VolunteerRow: View {
    @Environment(LocalKeyLogStore.self) private var store
    let volunteer: Volunteer

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(initials: volunteer.initials, name: volunteer.name)
            VStack(alignment: .leading, spacing: 3) {
                Text(volunteer.name).font(.headline)
                Text(volunteer.role).font(.subheadline).foregroundStyle(.secondary)
                if let phone = volunteer.phone { Text(phone).font(.caption).foregroundStyle(.secondary) }
                let heldKeys = store.keysHeld(by: volunteer.id)
                Text("Holds \(heldKeys.count) keys\(heldKeys.isEmpty ? "" : ": \(heldKeys.map(\.name).joined(separator: ", "))")")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 4)
    }
}

struct VolunteerDetailView: View {
    @Environment(LocalKeyLogStore.self) private var store
    let volunteerId: UUID
    private var volunteer: Volunteer? { store.volunteer(id: volunteerId) }

    var body: some View {
        List {
            if let volunteer {
                Section {
                    HStack(spacing: 12) {
                        AvatarView(initials: volunteer.initials, name: volunteer.name, size: 52)
                        VStack(alignment: .leading) {
                            Text(volunteer.name).font(.title2.bold())
                            Text(volunteer.role).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 8)
                }
                Section("Keys held") {
                    let held = store.keysHeld(by: volunteer.id)
                    if held.isEmpty { ContentUnavailableView("No keys held", systemImage: "key.slash") }
                    ForEach(held) { key in
                        NavigationLink { KeyDetailView(keyId: key.id) } label: { KeyRowView(key: key) }
                    }
                }
            }
        }.navigationTitle("Volunteer")
    }
}

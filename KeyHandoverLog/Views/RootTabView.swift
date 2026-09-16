import SwiftUI

struct RootTabView: View {
    @Environment(LocalKeyLogStore.self) private var store

    private var badgeCount: Int {
        store.overdueKeys().count + store.pendingHandovers().count
    }

    var body: some View {
        TabView {
            KeysListView()
                .tabItem { Label("Keys", systemImage: "key.fill") }
                .badge(badgeCount)
            VolunteersView()
                .tabItem { Label("Volunteers", systemImage: "person.3.fill") }
        }
    }
}

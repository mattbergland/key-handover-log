import SwiftUI

@main
struct KeyHandoverLogApp: App {
    @State private var store: LocalKeyLogStore

    init() {
        let store = LocalKeyLogStore()
        do { try store.load() } catch { store.lastError = error as? KeyLogStoreError }
        _store = State(initialValue: store)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(store)
                .alert("Key log error", isPresented: Binding(
                    get: { store.lastError != nil },
                    set: { if !$0 { store.lastError = nil } }
                )) {
                    Button("OK") { store.lastError = nil }
                } message: {
                    Text(store.lastError?.errorDescription ?? "Something went wrong.")
                }
        }
    }
}

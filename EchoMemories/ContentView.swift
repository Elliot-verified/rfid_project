import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: LocalStore
    @EnvironmentObject var appState: AppState
    @State private var showingAddGarment = false
    @State private var path = NavigationPath()

    var body: some View {
        TabView {
            NavigationStack(path: $path) {
                GarmentListView(
                    onSelectGarment: { id in
                        path.append(id)
                    },
                    onAddGarment: { showingAddGarment = true }
                )
                .navigationDestination(for: UUID.self) { garmentId in
                    GarmentDetailView(garmentId: garmentId)
                }
                .sheet(isPresented: $showingAddGarment) {
                    AddGarmentView()
                }
                .onChange(of: appState.pendingOpenGarmentId) { newId in
                    guard let id = newId, store.garment(byId: id) != nil else { return }
                    path = NavigationPath([id])
                }
            }
            .tabItem {
                Label("Journal", systemImage: "tshirt.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
    }
}

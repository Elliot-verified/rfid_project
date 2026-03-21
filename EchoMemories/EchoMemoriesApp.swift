import SwiftUI
import UIKit

@main
struct EchoMemoriesApp: App {
    @StateObject private var store = LocalStore.shared
    @StateObject private var appState = AppState.shared
    @StateObject private var syncService = SyncService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(appState)
                .environmentObject(syncService)
                .onOpenURL { url in
                    appState.handleOpenURL(url)
                }
                .task {
                    await syncService.syncIfNeeded()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    Task { await syncService.syncIfNeeded() }
                }
        }
    }
}

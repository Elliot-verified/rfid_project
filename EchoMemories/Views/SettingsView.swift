import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var syncService: SyncService
    @StateObject private var authService = AuthService.shared

    var body: some View {
        Form {
            if SupabaseClientManager.isConfigured {
                Section {
                    if let session = authService.session {
                        Text("Signed in")
                            .foregroundStyle(.secondary)
                        Button("Sign out", role: .destructive) {
                            Task { await authService.signOut() }
                        }
                    } else {
                        Button {
                            Task { await authService.signInWithApple() }
                        } label: {
                            HStack {
                                if authService.isSigningIn {
                                    ProgressView()
                                }
                                Text("Sign in with Apple")
                            }
                        }
                        .disabled(authService.isSigningIn)
                    }
                    if let err = authService.authError {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Account")
                }

                Section {
                    if let last = syncService.lastSyncDate {
                        Text("Last synced \(last, style: .relative) ago")
                            .foregroundStyle(.secondary)
                    }
                    Button("Sync now") {
                        Task { await syncService.syncIfNeeded() }
                    }
                    .disabled(authService.session == nil)
                    if let err = syncService.syncError {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Sync")
                }
            } else {
                Section {
                    Label("Sync coming soon", systemImage: "icloud")
                        .foregroundStyle(.secondary)
                    Text("Add SUPABASE_URL and SUPABASE_ANON_KEY to Info.plist for cloud backup.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Sync")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

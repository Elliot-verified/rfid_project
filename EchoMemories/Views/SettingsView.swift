import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var syncService: SyncService
    @StateObject private var authService = AuthService.shared

    /// What’s embedded at build time (safe: no keys printed). Use to verify TestFlight / Xcode Cloud.
    private var diagnosticsRows: [(label: String, value: String)] {
        let url = (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let key = (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let share = (Bundle.main.object(forInfoDictionaryKey: "PUBLIC_SHARE_BASE_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return [
            ("App version", "\(ver) (\(build))"),
            ("SUPABASE_URL", url.isEmpty ? "empty" : "set"),
            ("SUPABASE_ANON_KEY", key.isEmpty ? "empty" : "set"),
            ("PUBLIC_SHARE_BASE_URL", share.isEmpty ? "empty" : "set"),
            ("Supabase client", SupabaseClientManager.isConfigured ? "ready" : "not configured"),
            ("Auth session", authService.session != nil ? "signed in" : "not signed in"),
        ]
    }

    var body: some View {
        Form {
            if SupabaseClientManager.isConfigured {
                Section {
                    if authService.session != nil {
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
                    Text("Public NFC links use PUBLIC_SHARE_BASE_URL in Info.plist and the hosted share.html page. See README.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Sync")
                }
            } else {
                Section {
                    Label("Cloud backup unavailable in this build", systemImage: "icloud")
                        .foregroundStyle(.secondary)
                    Text("This install was built without Supabase URL and anon key. For TestFlight from Xcode Cloud, add SUPABASE_URL and SUPABASE_ANON_KEY as workflow environment variables (see README). For local Archive, keep Config/Secrets.xcconfig on the Mac you archive from.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Sync")
                }
            }

            Section {
                ForEach(diagnosticsRows, id: \.label) { row in
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.label)
                        Spacer(minLength: 8)
                        Text(row.value)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    .font(.footnote)
                }
            } header: {
                Text("Diagnostics")
            } footer: {
                Text("Shows whether keys are present in this build (not their values). Photos need URL + key set, Supabase client ready, and signed in.")
                    .font(.caption2)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

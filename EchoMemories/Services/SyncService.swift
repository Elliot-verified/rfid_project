import Foundation
import Supabase

/// Syncs garments and journal entries with Supabase. Pulls remote data and merges into LocalStore; pushes local changes.
final class SyncService: ObservableObject {
    static let shared = SyncService()

    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var syncError: String?

    private let store = LocalStore.shared

    private init() {}

    func syncIfNeeded() async {
        guard let client = SupabaseClientManager.client else { return }
        guard let session = try? await client.auth.session else { return }

        let userId = session.user.id.uuidString
        syncError = nil

        do {
            let garmentsResponse: PostgrestResponse<[Garment]> = try await client
                .from("garments")
                .select()
                .eq("user_id", value: userId)
                .execute()
            let remoteGarments = garmentsResponse.value

            let entriesResponse: PostgrestResponse<[JournalEntry]> = try await client
                .from("journal_entries")
                .select()
                .eq("user_id", value: userId)
                .execute()
            let remoteEntries = entriesResponse.value

            await MainActor.run {
                store.mergeGarments(remoteGarments)
                store.mergeEntries(remoteEntries)
                lastSyncDate = Date()
            }

            try await pushLocalChanges(client: client, userId: userId)
        } catch {
            await MainActor.run {
                syncError = error.localizedDescription
            }
        }
    }

    private func pushLocalChanges(client: SupabaseClient, userId: String) async throws {
        let garmentsToUpsert = store.garments.map { g in
            var copy = g
            copy.userId = userId
            return copy
        }
        let entriesToUpsert = store.entries.map { e in
            var copy = e
            copy.userId = userId
            return copy
        }
        if !garmentsToUpsert.isEmpty {
            try await client.from("garments").upsert(garmentsToUpsert).execute()
        }
        if !entriesToUpsert.isEmpty {
            try await client.from("journal_entries").upsert(entriesToUpsert).execute()
        }
    }
}

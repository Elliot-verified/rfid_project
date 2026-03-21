import Foundation
import Combine

/// Local-first persistence using Codable + FileManager. Supports iOS 15+.
final class LocalStore: ObservableObject {
    static let shared = LocalStore()

    @Published private(set) var garments: [Garment] = []
    @Published private(set) var entries: [JournalEntry] = []

    private let fileManager = FileManager.default
    private let garmentsFileName = "garments.json"
    private let entriesFileName = "entries.json"

    private var garmentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(garmentsFileName)
    }

    private var entriesURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(entriesFileName)
    }

    private init() {
        loadGarments()
        loadEntries()
    }

    // MARK: - Garments

    func addGarment(_ garment: Garment) {
        garments.append(garment)
        garments.sort { $0.createdAt > $1.createdAt }
        saveGarments()
    }

    func updateGarment(_ garment: Garment) {
        guard let idx = garments.firstIndex(where: { $0.id == garment.id }) else { return }
        var updated = garment
        updated.updatedAt = Date()
        garments[idx] = updated
        saveGarments()
    }

    func deleteGarment(_ garment: Garment) {
        garments.removeAll { $0.id == garment.id }
        entries.removeAll { $0.garmentId == garment.id }
        saveGarments()
        saveEntries()
    }

    func garment(byId id: UUID) -> Garment? {
        garments.first { $0.id == id }
    }

    func garment(byTagPayload payload: String) -> Garment? {
        garments.first { $0.tagPayload == payload }
    }

    func garment(byTagUID uid: String) -> Garment? {
        garments.first { $0.tagUID == uid }
    }

    private func loadGarments() {
        guard let data = try? Data(contentsOf: garmentsURL),
              let decoded = try? JSONDecoder().decode([Garment].self, from: data) else { return }
        garments = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func saveGarments() {
        guard let data = try? JSONEncoder().encode(garments) else { return }
        try? data.write(to: garmentsURL)
    }

    // MARK: - Entries

    func addEntry(_ entry: JournalEntry) {
        entries.append(entry)
        entries.sort { $0.wornDate > $1.wornDate }
        saveEntries()
    }

    func updateEntry(_ entry: JournalEntry) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        var updated = entry
        updated.updatedAt = Date()
        entries[idx] = updated
        saveEntries()
    }

    func deleteEntry(_ entry: JournalEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }

    func entries(for garmentId: UUID) -> [JournalEntry] {
        entries.filter { $0.garmentId == garmentId }.sorted { $0.wornDate > $1.wornDate }
    }

    private func loadEntries() {
        guard let data = try? Data(contentsOf: entriesURL),
              let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) else { return }
        entries = decoded.sorted { $0.wornDate > $1.wornDate }
    }

    private func saveEntries() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: entriesURL)
    }

    // MARK: - Sync (replace with server data when syncing)

    func replaceGarments(_ newGarments: [Garment]) {
        garments = newGarments.sorted { $0.createdAt > $1.createdAt }
        saveGarments()
    }

    func replaceEntries(_ newEntries: [JournalEntry]) {
        entries = newEntries.sorted { $0.wornDate > $1.wornDate }
        saveEntries()
    }

    func mergeGarments(_ remote: [Garment]) {
        var byId = Dictionary(uniqueKeysWithValues: garments.map { ($0.id, $0) })
        for g in remote {
            if let existing = byId[g.id] {
                byId[g.id] = g.updatedAt > existing.updatedAt ? g : existing
            } else {
                byId[g.id] = g
            }
        }
        garments = Array(byId.values).sorted { $0.createdAt > $1.createdAt }
        saveGarments()
    }

    func mergeEntries(_ remote: [JournalEntry]) {
        var byId = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
        for e in remote {
            if let existing = byId[e.id] {
                byId[e.id] = e.updatedAt > existing.updatedAt ? e : existing
            } else {
                byId[e.id] = e
            }
        }
        entries = Array(byId.values).sorted { $0.wornDate > $1.wornDate }
        saveEntries()
    }
}

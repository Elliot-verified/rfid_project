import Foundation
import UIKit

/// On-device JPEG for a journal entry when the user is not signed in (or before cloud upload).
/// File: Documents/EntryPhotos/<entryId>.jpg — not synced to Supabase by itself.
enum EntryLocalPhotoStore {
    private static var directoryURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("EntryPhotos", isDirectory: true)
    }

    static func fileURL(for entryId: UUID) -> URL {
        directoryURL.appendingPathComponent("\(entryId.uuidString).jpg")
    }

    static func exists(for entryId: UUID) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: entryId).path)
    }

    static func loadImage(for entryId: UUID) -> UIImage? {
        let url = fileURL(for: entryId)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func save(jpegData: Data, entryId: UUID) throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try jpegData.write(to: fileURL(for: entryId), options: .atomic)
    }

    static func delete(for entryId: UUID) {
        let url = fileURL(for: entryId)
        try? FileManager.default.removeItem(at: url)
    }
}

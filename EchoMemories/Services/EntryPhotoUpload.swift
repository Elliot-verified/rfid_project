import Foundation
import Supabase
import UIKit

enum EntryPhotoUpload {
    static let bucket = "entry-photos"

    /// Resized JPEG data suitable for upload (max long edge 1600px).
    static func jpegData(from image: UIImage, maxLongEdge: CGFloat = 1600) -> Data? {
        let scale = min(1, maxLongEdge / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        UIGraphicsBeginImageContextWithOptions(size, true, 1)
        image.draw(in: CGRect(origin: .zero, size: size))
        let scaled = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaled?.jpegData(compressionQuality: 0.82)
    }

    /// Uploads to `entry-photos/{userId}/{entryId}.jpg`. Returns storage object path for DB.
    static func upload(
        client: SupabaseClient,
        userId: String,
        entryId: UUID,
        imageData: Data
    ) async throws -> String {
        let path = "\(userId)/\(entryId.uuidString).jpg"
        let file = FileOptions(cacheControl: "3600", contentType: "image/jpeg", upsert: true)
        try await client.storage.from(bucket).upload(path, data: imageData, options: file)
        return path
    }

    static func deleteIfPresent(client: SupabaseClient, path: String) async throws {
        try await client.storage.from(bucket).remove(paths: [path])
    }
}

import Foundation

struct Garment: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    /// URL written to the NFC tag (e.g. echomemories://garment/<id>). Used for background open.
    var tagPayload: String?
    /// Tag UID when tag is read-only; we store garment by this instead of tagPayload.
    var tagUID: String?
    var createdAt: Date
    var updatedAt: Date
    var imageFileName: String?
    /// Set when synced to Supabase; used for RLS.
    var userId: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case tagPayload = "tag_payload"
        case tagUID = "tag_uid"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case imageFileName = "image_file_name"
        case userId = "user_id"
    }

    init(
        id: UUID = UUID(),
        name: String,
        tagPayload: String? = nil,
        tagUID: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        imageFileName: String? = nil,
        userId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.tagPayload = tagPayload
        self.tagUID = tagUID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.imageFileName = imageFileName
        self.userId = userId
    }

    /// URL to write to tag so iOS opens this garment when tapped.
    static func tagURL(for garmentId: UUID) -> String {
        "echomemories://garment/\(garmentId.uuidString)"
    }
}

import Foundation

struct JournalEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var garmentId: UUID
    /// The date the user wore the garment (may differ from createdAt).
    var wornDate: Date
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var mood: String?
    var location: String?
    /// Path inside Storage bucket `entry-photos` (e.g. `{user_uuid}/{entry_uuid}.jpg`).
    var photoStoragePath: String?
    /// Set when synced to Supabase; used for RLS.
    var userId: String?

    enum CodingKeys: String, CodingKey {
        case id, content, mood, location
        case garmentId = "garment_id"
        case wornDate = "worn_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case photoStoragePath = "photo_storage_path"
        case userId = "user_id"
    }

    init(
        id: UUID = UUID(),
        garmentId: UUID,
        wornDate: Date,
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        mood: String? = nil,
        location: String? = nil,
        photoStoragePath: String? = nil,
        userId: String? = nil
    ) {
        self.id = id
        self.garmentId = garmentId
        self.wornDate = wornDate
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.mood = mood
        self.location = location
        self.photoStoragePath = photoStoragePath
        self.userId = userId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        garmentId = try c.decode(UUID.self, forKey: .garmentId)
        wornDate = try c.decode(Date.self, forKey: .wornDate)
        content = try c.decode(String.self, forKey: .content)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        mood = try c.decodeIfPresent(String.self, forKey: .mood)
        location = try c.decodeIfPresent(String.self, forKey: .location)
        photoStoragePath = try c.decodeIfPresent(String.self, forKey: .photoStoragePath)
        userId = try c.decodeIfPresent(String.self, forKey: .userId)
    }
}

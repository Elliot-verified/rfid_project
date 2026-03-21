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
    /// Set when synced to Supabase; used for RLS.
    var userId: String?

    enum CodingKeys: String, CodingKey {
        case id, content, mood, location
        case garmentId = "garment_id"
        case wornDate = "worn_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
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
        self.userId = userId
    }
}

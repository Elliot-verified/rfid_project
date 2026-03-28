import Foundation

struct Garment: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    /// URL written to the NFC tag (e.g. echomemories://garment/<id> or https share URL). Used for background open.
    var tagPayload: String?
    /// Tag UID when tag is read-only; we store garment by this instead of tagPayload.
    var tagUID: String?
    var createdAt: Date
    var updatedAt: Date
    var imageFileName: String?
    /// When true, synced rows are readable anonymously (share page + NFC HTTPS URL).
    var isPublic: Bool
    /// Set when synced to Supabase; used for RLS.
    var userId: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case tagPayload = "tag_payload"
        case tagUID = "tag_uid"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case imageFileName = "image_file_name"
        case isPublic = "is_public"
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
        isPublic: Bool = false,
        userId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.tagPayload = tagPayload
        self.tagUID = tagUID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.imageFileName = imageFileName
        self.isPublic = isPublic
        self.userId = userId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        tagPayload = try c.decodeIfPresent(String.self, forKey: .tagPayload)
        tagUID = try c.decodeIfPresent(String.self, forKey: .tagUID)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        imageFileName = try c.decodeIfPresent(String.self, forKey: .imageFileName)
        isPublic = try c.decodeIfPresent(Bool.self, forKey: .isPublic) ?? false
        userId = try c.decodeIfPresent(String.self, forKey: .userId)
    }

    /// Opens this garment in the Echo Memories app.
    static func appDeepLink(for garmentId: UUID) -> String {
        "echomemories://garment/\(garmentId.uuidString)"
    }

    /// URL to write to the tag: public HTTPS share page when `isPublic` and `PUBLIC_SHARE_BASE_URL` are set; otherwise app deep link.
    static func nfcWrittenURL(for garmentId: UUID, isPublic: Bool) -> String {
        if isPublic {
            let trimmed = AppBuildSecrets.publicShareBaseURLString
            guard !trimmed.isEmpty else { return appDeepLink(for: garmentId) }
            let noSlash = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return "\(noSlash)/share.html?id=\(garmentId.uuidString)"
        }
        return appDeepLink(for: garmentId)
    }

    func nfcWrittenURL() -> String {
        Self.nfcWrittenURL(for: id, isPublic: isPublic)
    }
}

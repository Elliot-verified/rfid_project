import Foundation
import Supabase

/// Provides a configured Supabase client when SUPABASE_URL and SUPABASE_ANON_KEY are set in Info.plist.
enum SupabaseClientManager {
    static let jsonDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: string) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            guard let fallback = formatter.date(from: string) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
            }
            return fallback
        }
        return d
    }()

    static let jsonEncoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    static var client: SupabaseClient? {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !urlString.isEmpty,
              let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty,
              let url = URL(string: urlString) else { return nil }
        let options = SupabaseClientOptions(
            db: .init(encoder: jsonEncoder, decoder: jsonDecoder)
        )
        return SupabaseClient(supabaseURL: url, supabaseKey: key, options: options)
    }

    static var isConfigured: Bool { client != nil }

    /// Public object URL for Storage (bucket must be public or use signed URLs elsewhere).
    static func publicStorageObjectURL(bucket: String, objectPath: String) -> URL? {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !urlString.isEmpty else { return nil }
        let base = urlString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let encodedPath = objectPath.split(separator: "/").map { $0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }.joined(separator: "/")
        return URL(string: "\(base)/storage/v1/object/public/\(bucket)/\(encodedPath)")
    }
}

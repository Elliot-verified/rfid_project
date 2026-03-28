import Foundation

/// Supabase + share URL for this build. Prefers values injected at build time on Xcode Cloud
/// (`GeneratedSupabaseConfig`); otherwise uses Info.plist from `Config/Secrets.xcconfig`.
enum AppBuildSecrets {
    private static func string(fromBase64 b64: String) -> String? {
        let t = b64.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, let data = Data(base64Encoded: t), let s = String(data: data, encoding: .utf8) else { return nil }
        let u = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return u.isEmpty ? nil : u
    }

    static var supabaseURLString: String {
        if let s = string(fromBase64: GeneratedSupabaseConfig.supabaseURLB64) { return s }
        return (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var supabaseAnonKey: String {
        if let s = string(fromBase64: GeneratedSupabaseConfig.supabaseAnonKeyB64) { return s }
        return (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var publicShareBaseURLString: String {
        if let s = string(fromBase64: GeneratedSupabaseConfig.publicShareBaseURLB64) { return s }
        return (Bundle.main.object(forInfoDictionaryKey: "PUBLIC_SHARE_BASE_URL") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

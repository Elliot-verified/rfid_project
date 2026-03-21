import Foundation
import AuthenticationServices
import Supabase

/// Handles Sign in with Apple and Supabase auth session.
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var session: Session?
    @Published private(set) var isSigningIn = false
    @Published private(set) var authError: String?

    private init() {
        Task { await refreshSession() }
    }

    func refreshSession() async {
        guard let client = SupabaseClientManager.client else { return }
        session = try? await client.auth.session
    }

    func signInWithApple() async {
        guard SupabaseClientManager.isConfigured else {
            authError = "Supabase not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY to Info.plist."
            return
        }
        isSigningIn = true
        authError = nil
        defer { isSigningIn = false }

        do {
            let credential = try await performAppleSignIn()
            guard let idTokenData = credential.identityToken,
                  let idToken = String(data: idTokenData, encoding: .utf8) else {
                authError = "Could not get Apple ID token."
                return
            }
            let client = SupabaseClientManager.client!
            _ = try await client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken)
            )
            await refreshSession()
        } catch {
            if (error as NSError).code != 1001 {
                authError = error.localizedDescription
            }
        }
    }

    private func performAppleSignIn() async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleSignInDelegate(continuation: continuation)
            controller.delegate = delegate
            controller.performRequests()
            objc_setAssociatedObject(controller, &AssociatedKeys.delegate, delegate, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    func signOut() async {
        guard let client = SupabaseClientManager.client else { return }
        try? await client.auth.signOut()
        await refreshSession()
    }

    private enum AssociatedKeys {
        static var delegate = 0
    }
}

private final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    let continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>

    init(continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>) {
        self.continuation = continuation
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation.resume(throwing: NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid credential"]))
            return
        }
        continuation.resume(returning: credential)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
}

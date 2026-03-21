import Foundation
import SwiftUI

/// Global app state: pending NFC-open garment, auth, etc.
final class AppState: ObservableObject {
    static let shared = AppState()

    /// When the app is opened via echomemories://garment/<id>, we navigate here.
    @Published var pendingOpenGarmentId: UUID?

    private init() {}

    func handleOpenURL(_ url: URL) {
        guard url.scheme == "echomemories",
              url.host == "garment",
              url.pathComponents.count >= 2 else { return }
        let idString = url.pathComponents[1]
        guard let id = UUID(uuidString: idString) else { return }
        pendingOpenGarmentId = id
        // Clear after a short delay so we don't re-navigate on every appearance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.pendingOpenGarmentId = nil
        }
    }
}

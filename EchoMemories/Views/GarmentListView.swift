import SwiftUI

struct GarmentListView: View {
    @EnvironmentObject var store: LocalStore
    let onSelectGarment: (UUID) -> Void
    let onAddGarment: () -> Void
    @State private var isScanning = false
    @State private var scanAlertMessage: String?

    var body: some View {
        List {
            ForEach(store.garments) { garment in
                Button {
                    onSelectGarment(garment.id)
                } label: {
                    HStack {
                        Text(garment.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Echo Memories")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    onAddGarment()
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    scanTag()
                } label: {
                    if isScanning {
                        ProgressView()
                    } else {
                        Label("Scan tag", systemImage: "wave.3.right.circle")
                    }
                }
                .disabled(isScanning || store.garments.isEmpty)
            }
        }
        .alert("Scan tag", isPresented: Binding(
            get: { scanAlertMessage != nil },
            set: { if !$0 { scanAlertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { scanAlertMessage = nil }
        } message: {
            Text(scanAlertMessage ?? "")
        }
        .overlay {
            if store.garments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tshirt.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No garments yet")
                        .font(.headline)
                    Text("Tap + to add a garment and link an NFC tag.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
    }

    private func scanTag() {
        isScanning = true
        Task {
            do {
                let url = try await NFCService.shared.readURLFromTag()
                await MainActor.run {
                    isScanning = false
                    if let url = url, let garment = store.garment(byTagPayload: url) ?? store.garment(byTagUID: url) {
                        onSelectGarment(garment.id)
                    } else if let url = url {
                        scanAlertMessage = "This tag isn’t linked to a garment. Add a garment and link it to this tag first."
                    } else {
                        scanAlertMessage = "No URL found on the tag. Make sure the tag was linked in the app."
                    }
                }
            } catch {
                await MainActor.run {
                    isScanning = false
                    if (error as NSError).code != 1001 {
                        scanAlertMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}

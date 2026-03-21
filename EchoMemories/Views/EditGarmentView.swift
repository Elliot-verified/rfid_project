import SwiftUI

struct EditGarmentView: View {
    @EnvironmentObject var store: LocalStore
    @Environment(\.dismiss) private var dismiss
    let garment: Garment
    @State private var name: String = ""
    @State private var isPublic: Bool = false
    @State private var isRelinkingTag = false
    @State private var tagError: String?
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                        .focused($isNameFocused)
                }

                Section {
                    Toggle("Public memories page", isOn: $isPublic)
                    Text("Anyone with the link encoded on the NFC tag can view this garment and its memories in a browser after you sync to Supabase. Your App ID must allow public read (see schema).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button {
                        Task { await relinkNFC() }
                    } label: {
                        HStack {
                            if isRelinkingTag { ProgressView() }
                            Text(isRelinkingTag ? "Hold phone to tag…" : "Write NFC tag with current link")
                        }
                    }
                    .disabled(isRelinkingTag)
                } header: {
                    Text("Sharing & NFC")
                } footer: {
                    Text("Set PUBLIC_SHARE_BASE_URL in Info.plist to your hosted copy of web/share.html (no trailing slash). Public tags store that HTTPS URL; private tags use the Echo Memories app link.")
                        .font(.footnote)
                }
            }
            .navigationTitle("Edit garment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                name = garment.name
                isPublic = garment.isPublic
                isNameFocused = true
            }
            .alert("Could not write tag", isPresented: .init(
                get: { tagError != nil },
                set: { if !$0 { tagError = nil } }
            )) {
                Button("OK", role: .cancel) { tagError = nil }
            } message: {
                Text(tagError ?? "")
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var updated = garment
        updated.name = trimmed
        updated.isPublic = isPublic
        store.updateGarment(updated)
        dismiss()
    }

    private func relinkNFC() async {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var g = garment
        g.name = trimmed
        g.isPublic = isPublic
        let url = g.nfcWrittenURL()
        await MainActor.run {
            isRelinkingTag = true
            tagError = nil
        }
        do {
            try await NFCService.shared.writeURLToTag(url)
            await MainActor.run {
                g.tagPayload = url
                store.updateGarment(g)
                isRelinkingTag = false
            }
        } catch {
            await MainActor.run {
                isRelinkingTag = false
                tagError = error.localizedDescription
            }
        }
    }
}

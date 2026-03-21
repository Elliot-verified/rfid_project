import PhotosUI
import SwiftUI

struct EntryFormView: View {
    @EnvironmentObject var store: LocalStore
    let garmentId: UUID
    let initialWornDate: Date
    let existingEntry: JournalEntry?
    let onDismiss: () -> Void

    @State private var wornDate: Date
    @State private var content: String = ""
    @State private var mood: String = ""
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var pendingImage: UIImage?
    @State private var removeRemotePhoto = false

    private var canUseCloudPhoto: Bool {
        SupabaseClientManager.isConfigured && AuthService.shared.session != nil
    }

    init(garmentId: UUID, initialWornDate: Date, existingEntry: JournalEntry? = nil, onDismiss: @escaping () -> Void) {
        self.garmentId = garmentId
        self.initialWornDate = initialWornDate
        self.existingEntry = existingEntry
        self.onDismiss = onDismiss
        _wornDate = State(initialValue: existingEntry?.wornDate ?? initialWornDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("When did you wear it?") {
                    DatePicker("Date", selection: $wornDate, displayedComponents: .date)
                }
                Section("Memory") {
                    TextField("What happened? Where did you go?", text: $content, axis: .vertical)
                        .lineLimit(3...8)
                    TextField("Mood (optional)", text: $mood)
                }
                Section {
                    if let pendingImage {
                        Image(uiImage: pendingImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else if !removeRemotePhoto, let path = existingEntry?.photoStoragePath,
                              let url = SupabaseClientManager.publicStorageObjectURL(bucket: EntryPhotoUpload.bucket, objectPath: path) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .failure:
                                Text("Could not load photo")
                                    .foregroundStyle(.secondary)
                            case .empty:
                                ProgressView()
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    if canUseCloudPhoto {
                        PhotosPicker(selection: $photoPickerItem, matching: .images) {
                            Label(pendingImage == nil && existingEntry?.photoStoragePath == nil ? "Add photo" : "Change photo", systemImage: "photo")
                        }
                        if pendingImage != nil || existingEntry?.photoStoragePath != nil {
                            Button("Remove photo", role: .destructive) {
                                pendingImage = nil
                                photoPickerItem = nil
                                removeRemotePhoto = true
                            }
                        }
                    } else {
                        Text("Sign in with Apple (Settings) to attach photos that sync to the cloud.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Photo")
                }
            }
            .navigationTitle(existingEntry == nil ? "New entry" : "Edit entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .onAppear {
                if let e = existingEntry {
                    content = e.content
                    mood = e.mood ?? ""
                }
            }
            .onChange(of: photoPickerItem) { newItem in
                Task {
                    guard let newItem else { return }
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let ui = UIImage(data: data) {
                        await MainActor.run {
                            pendingImage = ui
                            removeRemotePhoto = false
                        }
                    }
                }
            }
            .alert("Could not save photo", isPresented: .init(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    private func save() async {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }
        await MainActor.run { isSaving = true }

        let entryId = existingEntry?.id ?? UUID()
        var photoPath = existingEntry?.photoStoragePath

        if removeRemotePhoto, let old = existingEntry?.photoStoragePath,
           let client = SupabaseClientManager.client {
            try? await EntryPhotoUpload.deleteIfPresent(client: client, path: old)
            photoPath = nil
        }

        if let img = pendingImage,
           let client = SupabaseClientManager.client,
           let session = try? await client.auth.session {
            let uid = session.user.id.uuidString
            guard let data = EntryPhotoUpload.jpegData(from: img) else {
                await MainActor.run {
                    isSaving = false
                    saveError = "Could not prepare image."
                }
                return
            }
            do {
                photoPath = try await EntryPhotoUpload.upload(client: client, userId: uid, entryId: entryId, imageData: data)
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = error.localizedDescription
                }
                return
            }
        }

        await MainActor.run {
            if let existing = existingEntry {
                var updated = existing
                updated.wornDate = wornDate
                updated.content = trimmedContent
                updated.mood = mood.isEmpty ? nil : mood
                updated.photoStoragePath = photoPath
                store.updateEntry(updated)
            } else {
                let entry = JournalEntry(
                    id: entryId,
                    garmentId: garmentId,
                    wornDate: wornDate,
                    content: trimmedContent,
                    mood: mood.isEmpty ? nil : mood,
                    photoStoragePath: photoPath
                )
                store.addEntry(entry)
            }
            isSaving = false
            onDismiss()
        }
    }
}

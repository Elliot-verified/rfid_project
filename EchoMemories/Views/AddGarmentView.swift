import SwiftUI

struct AddGarmentView: View {
    @EnvironmentObject var store: LocalStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var isWritingTag = false
    @State private var writeError: String?
    @State private var didWriteTag = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Garment name", text: $name)
                        .textContentType(.name)
                } header: {
                    Text("Name")
                }

                if didWriteTag {
                    Label("Tag linked. Tap the tag to open this garment.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Section {
                        Button {
                            writeTag()
                        } label: {
                            HStack {
                                if isWritingTag {
                                    ProgressView()
                                }
                                Text(isWritingTag ? "Hold phone to tag…" : "Link NFC tag")
                            }
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isWritingTag)
                        .alert("Write failed", isPresented: .init(
                            get: { writeError != nil },
                            set: { if !$0 { writeError = nil } }
                        )) {
                            Button("OK", role: .cancel) { writeError = nil }
                        } message: {
                            Text(writeError ?? "")
                        }
                    } header: {
                        Text("NFC tag")
                    } footer: {
                        Text("Sew the tag into your clothing, then hold your iPhone near it to link this garment. Next time you tap the tag, the app will open to this garment.")
                    }
                }
            }
            .navigationTitle("Add garment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(!canFinish)
                }
            }
        }
    }

    private var canFinish: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func writeTag() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let garment = Garment(name: trimmed)
        let url = Garment.tagURL(for: garment.id)
        isWritingTag = true
        writeError = nil

        Task {
            do {
                try await NFCService.shared.writeURLToTag(url)
                await MainActor.run {
                    var g = garment
                    g.tagPayload = url
                    store.addGarment(g)
                    didWriteTag = true
                    isWritingTag = false
                }
            } catch {
                await MainActor.run {
                    writeError = error.localizedDescription
                    isWritingTag = false
                    var g = garment
                    store.addGarment(g)
                    didWriteTag = false
                }
            }
        }
    }
}

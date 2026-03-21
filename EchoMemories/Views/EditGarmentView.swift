import SwiftUI

struct EditGarmentView: View {
    @EnvironmentObject var store: LocalStore
    @Environment(\.dismiss) private var dismiss
    let garment: Garment
    @State private var name: String = ""
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                    .textContentType(.name)
                    .focused($isNameFocused)
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
                isNameFocused = true
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var updated = garment
        updated.name = trimmed
        store.updateGarment(updated)
        dismiss()
    }
}

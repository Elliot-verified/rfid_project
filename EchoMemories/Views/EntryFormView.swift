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
                        save()
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
        }
    }

    private func save() {
        isSaving = true
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = existingEntry {
            var updated = existing
            updated.wornDate = wornDate
            updated.content = trimmedContent
            updated.mood = mood.isEmpty ? nil : mood
            store.updateEntry(updated)
        } else {
            let entry = JournalEntry(
                garmentId: garmentId,
                wornDate: wornDate,
                content: trimmedContent,
                mood: mood.isEmpty ? nil : mood
            )
            store.addEntry(entry)
        }
        isSaving = false
        onDismiss()
    }
}

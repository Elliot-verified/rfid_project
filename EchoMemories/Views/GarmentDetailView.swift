import SwiftUI

struct GarmentDetailView: View {
    @EnvironmentObject var store: LocalStore
    @Environment(\.dismiss) private var dismiss
    let garmentId: UUID
    @State private var showingEntryForm = false
    @State private var entryWornDate = Date()
    @State private var entryToEdit: JournalEntry?
    @State private var showingEditGarment = false
    @State private var showingDeleteConfirm = false

    private var garment: Garment? { store.garment(byId: garmentId) }
    private var entries: [JournalEntry] { store.entries(for: garmentId) }

    var body: some View {
        Group {
            if let g = garment {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(g.name)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Button {
                            entryWornDate = Date()
                            entryToEdit = nil
                            showingEntryForm = true
                        } label: {
                            Label("Add memory", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.borderedProminent)

                        if entries.isEmpty {
                            Text("No entries yet. Tap a tag or add a memory above.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Memories")
                                    .font(.headline)
                                ForEach(entries) { entry in
                                    EntryRowView(entry: entry)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            entryToEdit = entry
                                            showingEntryForm = true
                                        }
                                        .contextMenu {
                                            Button {
                                                entryToEdit = entry
                                                showingEntryForm = true
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            Button(role: .destructive) {
                                                store.deleteEntry(entry)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle(g.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                showingEditGarment = true
                            } label: {
                                Label("Edit name", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                showingDeleteConfirm = true
                            } label: {
                                Label("Delete garment", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .sheet(isPresented: $showingEntryForm) {
                    EntryFormView(
                        garmentId: garmentId,
                        initialWornDate: entryWornDate,
                        existingEntry: entryToEdit,
                        onDismiss: {
                            showingEntryForm = false
                            entryToEdit = nil
                        }
                    )
                }
                .sheet(isPresented: $showingEditGarment) {
                    EditGarmentView(garment: g)
                }
                .alert("Delete garment?", isPresented: $showingDeleteConfirm) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        store.deleteGarment(g)
                        dismiss()
                    }
                } message: {
                    Text("This will remove \"\(g.name)\" and all its memories. This cannot be undone.")
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "tshirt")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Garment not found")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct EntryRowView: View {
    let entry: JournalEntry
    private static var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    private var photoURL: URL? {
        guard let path = entry.photoStoragePath else { return nil }
        return SupabaseClientManager.publicStorageObjectURL(bucket: EntryPhotoUpload.bucket, objectPath: path)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let url = photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Color.gray.opacity(0.15)
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(Self.dateFormatter.string(from: entry.wornDate))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Text(entry.content)
                    .font(.body)
            }
        }
        .padding(.vertical, 4)
    }
}

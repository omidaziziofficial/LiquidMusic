import SwiftUI

public struct NewPlaylistSheet: View {
    public let palette: LiquidPalette
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Playlist name", text: $name)
                }
            }
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            _ = LibraryStore.shared.createPlaylist(name: trimmed)
                        }
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(palette.accent)
                }
            }
        }
    }
}

public struct RenamePlaylistSheet: View {
    public let playlistId: Int64
    public let currentName: String
    public let palette: LiquidPalette
    @Environment(\.dismiss) private var dismiss
    @State private var newName: String = ""
    
    public init(playlistId: Int64, currentName: String, palette: LiquidPalette) {
        self.playlistId = playlistId
        self.currentName = currentName
        self.palette = palette
        _newName = State(initialValue: currentName)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Playlist name", text: $newName)
                }
            }
            .navigationTitle("Rename")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            LibraryStore.shared.renamePlaylist(id: playlistId, newName: trimmed)
                        }
                        dismiss()
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(palette.accent)
                }
            }
        }
    }
}

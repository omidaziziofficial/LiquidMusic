import SwiftUI
import PhotosUI

public struct PlaylistCoverSheet: View {
    public let playlistId: Int64
    public let palette: LiquidPalette
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store = LibraryStore.shared
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCameraPicker: Bool = false
    @State private var showSongPicker: Bool = false
    
    public var body: some View {
        NavigationStack {
            List {
                Button {
                    store.updatePlaylistCover(playlistId: playlistId, mode: 0)
                    dismiss()
                } label: {
                    Label("Mix of Song Covers", systemImage: "square.grid.2x2")
                }
                
                Button {
                    showSongPicker = true
                } label: {
                    Label("Cover of a Song", systemImage: "music.note")
                }
                
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Choose From Gallery", systemImage: "photo")
                }
                
                Button(role: .destructive) {
                    store.updatePlaylistCover(playlistId: playlistId, mode: 0, customPath: nil)
                    dismiss()
                } label: {
                    Label("Remove Custom Cover", systemImage: "trash")
                }
            }
            .navigationTitle("Playlist Cover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        saveCustomImage(img)
                    }
                }
            }
            .sheet(isPresented: $showSongPicker) {
                SongPickerView(playlistId: playlistId, palette: palette)
            }
        }
    }
    
    private func saveCustomImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        let filename = "playlist_cover_\(playlistId)_\(Int(Date().timeIntervalSince1970)).jpg"
        let target = store.coversDirectoryURL.appendingPathComponent(filename)
        try? data.write(to: target)
        store.updatePlaylistCover(playlistId: playlistId, mode: 2, customPath: target.path)
        dismiss()
    }
}

public struct SongPickerView: View {
    public let playlistId: Int64
    public let palette: LiquidPalette
    @ObservedObject var store = LibraryStore.shared
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        NavigationStack {
            List(store.songs) { song in
                Button {
                    store.updatePlaylistCover(playlistId: playlistId, mode: 1, songId: song.id)
                    dismiss()
                } label: {
                    HStack {
                        ArtworkImageView(song: song, size: 40, cornerRadius: 8)
                        VStack(alignment: .leading) {
                            Text(song.title).font(.body).foregroundColor(palette.text)
                            Text(song.artist).font(.subheadline).foregroundColor(palette.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Choose a Song")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

public struct AddSongsSheet: View {
    public let playlistId: Int64
    public let palette: LiquidPalette
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store = LibraryStore.shared
    @State private var selectedSongIds: Set<Int64> = []
    
    public var body: some View {
        NavigationStack {
            List(store.songs) { song in
                Button {
                    if selectedSongIds.contains(song.id) {
                        selectedSongIds.remove(song.id)
                    } else {
                        selectedSongIds.insert(song.id)
                    }
                } label: {
                    HStack {
                        ArtworkImageView(song: song, size: 42, cornerRadius: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(song.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(palette.text)
                            Text(song.artist)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(palette.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: selectedSongIds.contains(song.id) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(selectedSongIds.contains(song.id) ? palette.accent : palette.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Add Songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(selectedSongIds.count))") {
                        store.addSongsToPlaylist(playlistId: playlistId, songIds: Array(selectedSongIds))
                        dismiss()
                    }
                    .disabled(selectedSongIds.isEmpty)
                    .foregroundColor(palette.accent)
                }
            }
        }
    }
}

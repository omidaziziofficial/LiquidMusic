import SwiftUI
import PhotosUI

public struct SongActionMenuSheet: View {
    public let song: Song
    public let palette: LiquidPalette
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var store = LibraryStore.shared
    @ObservedObject var player = AudioPlayerService.shared
    
    @State private var showTagEditor: Bool = false
    @State private var showLyricsEditor: Bool = false
    @State private var showAddToPlaylist: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var shareItems: [Any] = []
    
    public var body: some View {
        NavigationStack {
            List {
                // Header Preview
                HStack(spacing: 14) {
                    ArtworkImageView(song: song, size: 54, cornerRadius: 10)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(song.title)
                            .font(.headline)
                            .foregroundColor(palette.text)
                            .lineLimit(1)
                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundColor(palette.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 4)
                
                Section {
                    Button {
                        player.addToQueueNext(song: song)
                        dismiss()
                    } label: {
                        Label("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward")
                    }
                    
                    Button {
                        player.addToQueueLast(song: song)
                        dismiss()
                    } label: {
                        Label("Play Last", systemImage: "text.line.last.and.arrowtriangle.forward")
                    }
                    
                    Button {
                        showAddToPlaylist = true
                    } label: {
                        Label("Add to Playlist", systemImage: "plus.circle")
                    }
                    
                    Button {
                        store.toggleFavorite(songId: song.id)
                        dismiss()
                    } label: {
                        Label(store.isFavorite(songId: song.id) ? "Remove from Favorites" : "Favorite",
                              systemImage: store.isFavorite(songId: song.id) ? "heart.slash" : "heart")
                    }
                }
                
                Section {
                    Button {
                        showTagEditor = true
                    } label: {
                        Label("Edit Info", systemImage: "pencil")
                    }
                    
                    Button {
                        showLyricsEditor = true
                    } label: {
                        Label("Lyrics", systemImage: "quote.bubble")
                    }
                    
                    Button {
                        shareSong()
                    } label: {
                        Label("Share Song", systemImage: "square.and.arrow.up")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        // Remove song from device
                        try? FileManager.default.removeItem(atPath: song.path)
                        Task { await store.rescanLibrary() }
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showTagEditor) {
                TagEditorSheet(song: song, palette: palette)
            }
            .sheet(isPresented: $showLyricsEditor) {
                LyricsEditorSheet(song: song, palette: palette)
            }
            .sheet(isPresented: $showAddToPlaylist) {
                AddToPlaylistPickerSheet(song: song, palette: palette)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: shareItems)
            }
        }
    }
    
    private func shareSong() {
        let fileURL = URL(fileURLWithPath: song.path)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            shareItems = [fileURL]
            showShareSheet = true
        }
    }
}

// MARK: - Add To Playlist Picker
public struct AddToPlaylistPickerSheet: View {
    public let song: Song
    public let palette: LiquidPalette
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store = LibraryStore.shared
    
    public var body: some View {
        NavigationStack {
            List(store.playlists) { pl in
                Button {
                    store.addSongsToPlaylist(playlistId: pl.id, songIds: [song.id])
                    dismiss()
                } label: {
                    HStack {
                        PlaylistArtworkView(playlist: pl, size: 40, cornerRadius: 8)
                        Text(pl.name).foregroundColor(palette.text)
                        Spacer()
                        Text("\(pl.songIds.count)").foregroundColor(palette.secondary)
                    }
                }
            }
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Lyrics Editor Sheet
public struct LyricsEditorSheet: View {
    public let song: Song
    public let palette: LiquidPalette
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var lyricsService = LyricsService.shared
    
    @State private var lyricsText: String = ""
    
    public var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $lyricsText)
                    .padding(8)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
                
                HStack(spacing: 16) {
                    Button("Fetch Again") {
                        Task {
                            if let fetched = await lyricsService.fetchOnlineLyrics(for: song) {
                                lyricsText = fetched.raw
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Remove Lyrics", role: .destructive) {
                        lyricsService.deleteLyrics(for: song)
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.bottom, 16)
            }
            .navigationTitle("Lyrics Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        lyricsService.saveLyrics(for: song, text: lyricsText)
                        dismiss()
                    }
                    .foregroundColor(palette.accent)
                }
            }
            .task {
                if let l = await lyricsService.loadLyrics(for: song) {
                    lyricsText = l.raw
                }
            }
        }
    }
}

// MARK: - Tag Editor Sheet
public struct TagEditorSheet: View {
    public let song: Song
    public let palette: LiquidPalette
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store = LibraryStore.shared
    
    @State private var title: String
    @State private var artist: String
    @State private var album: String
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var customCoverImage: UIImage?
    
    public init(song: Song, palette: LiquidPalette) {
        self.song = song
        self.palette = palette
        _title = State(initialValue: song.title)
        _artist = State(initialValue: song.artist)
        _album = State(initialValue: song.album)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Cover")) {
                    HStack {
                        if let img = customCoverImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            ArtworkImageView(song: song, size: 64, cornerRadius: 10)
                        }
                        
                        Spacer()
                        
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Text("Change Cover")
                                .foregroundColor(palette.accent)
                        }
                    }
                }
                
                Section(header: Text("Details")) {
                    TextField("Title", text: $title)
                    TextField("Artist", text: $artist)
                    TextField("Album", text: $album)
                }
            }
            .navigationTitle("Edit Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateSongTags(
                            songId: song.id,
                            title: title,
                            artist: artist,
                            album: album,
                            customCoverImage: customCoverImage
                        )
                        dismiss()
                    }
                    .foregroundColor(palette.accent)
                }
            }
            .onChange(of: selectedPhotoItem) { item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        customCoverImage = img
                    }
                }
            }
        }
    }
}

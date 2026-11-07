import SwiftUI

public struct PlaylistsView: View {
    @ObservedObject var store = LibraryStore.shared
    public let palette: LiquidPalette
    
    @State private var showNewPlaylistSheet: Bool = false
    @State private var showImportPicker: Bool = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    public var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Top Actions: New Playlist & Import
                    HStack(spacing: 12) {
                        Button {
                            showNewPlaylistSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("New Playlist")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(palette.accent)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        
                        Button {
                            showImportPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Import")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(palette.surface)
                            .foregroundColor(palette.text)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(palette.separator, lineWidth: 0.6)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    // Playlists Grid
                    if store.playlists.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 48))
                                .foregroundColor(palette.tertiary)
                            Text("No Playlists Yet")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(palette.text)
                            Text("Tap New Playlist to create your first music collection.")
                                .font(.subheadline)
                                .foregroundColor(palette.secondary)
                        }
                        .padding(.top, 60)
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(store.playlists) { playlist in
                                NavigationLink {
                                    PlaylistDetailView(playlist: playlist, palette: palette)
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        PlaylistArtworkView(playlist: playlist, size: 165, cornerRadius: 16)
                                            .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(playlist.name)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(palette.text)
                                                .lineLimit(1)
                                            
                                            Text("\(playlist.songIds.count) songs")
                                                .font(.system(size: 13, weight: .regular))
                                                .foregroundColor(palette.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer()
                        .frame(height: 140)
                }
            }
        }
        .navigationTitle("Playlists")
        .sheet(isPresented: $showNewPlaylistSheet) {
            NewPlaylistSheet(palette: palette)
        }
    }
}

// MARK: - Playlist Artwork View (Mix of 4, Single, or Custom)
public struct PlaylistArtworkView: View {
    public let playlist: Playlist
    public let size: CGFloat
    public let cornerRadius: CGFloat
    
    @ObservedObject var store = LibraryStore.shared
    
    public var body: some View {
        Group {
            if let custom = playlist.coverPath, let img = UIImage(contentsOfFile: custom) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else if playlist.coverMode == 1, let songId = playlist.coverSongId, let song = store.songsMap[songId] {
                ArtworkImageView(song: song, size: size, cornerRadius: cornerRadius)
            } else {
                // 4-song mix or fallback
                let sampleSongs = Array(playlist.songIds.prefix(4)).compactMap { store.songsMap[$0] }
                if sampleSongs.count >= 4 {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            ArtworkImageView(song: sampleSongs[0], size: size / 2, cornerRadius: 0)
                            ArtworkImageView(song: sampleSongs[1], size: size / 2, cornerRadius: 0)
                        }
                        HStack(spacing: 0) {
                            ArtworkImageView(song: sampleSongs[2], size: size / 2, cornerRadius: 0)
                            ArtworkImageView(song: sampleSongs[3], size: size / 2, cornerRadius: 0)
                        }
                    }
                } else if let firstSong = sampleSongs.first {
                    ArtworkImageView(song: firstSong, size: size, cornerRadius: cornerRadius)
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [Color(hex: 0x5E5CE6), Color(hex: 0xBF5AF2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: "music.note.list")
                            .font(.system(size: size * 0.4, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Playlist Detail View
public struct PlaylistDetailView: View {
    public let playlist: Playlist
    public let palette: LiquidPalette
    @ObservedObject var store = LibraryStore.shared
    @ObservedObject var player = AudioPlayerService.shared
    
    @State private var showAddSongsSheet: Bool = false
    @State private var showRenameSheet: Bool = false
    @State private var showCoverSheet: Bool = false
    @State private var showShareExport: Bool = false
    @State private var exportZipURL: URL?
    @State private var selectedSongForMenu: Song?
    @Environment(\.dismiss) private var dismiss
    
    public var currentPlaylist: Playlist {
        store.playlists.first(where: { $0.id == playlist.id }) ?? playlist
    }
    
    public var songs: [Song] {
        currentPlaylist.songIds.compactMap { store.songsMap[$0] }
    }
    
    public var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header Artwork & Info
                    VStack(spacing: 12) {
                        PlaylistArtworkView(playlist: currentPlaylist, size: 200, cornerRadius: 20)
                            .shadow(color: Color.black.opacity(0.25), radius: 14, x: 0, y: 8)
                        
                        Text(currentPlaylist.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(palette.text)
                        
                        Text("\(songs.count) songs")
                            .font(.subheadline)
                            .foregroundColor(palette.secondary)
                    }
                    .padding(.top, 10)
                    
                    // Actions
                    HStack(spacing: 12) {
                        Button {
                            player.playSongs(songs, startIndex: 0, shuffle: false)
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Play")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(palette.accent)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .disabled(songs.isEmpty)
                        
                        Button {
                            player.playSongs(songs, startIndex: 0, shuffle: true)
                        } label: {
                            HStack {
                                Image(systemName: "shuffle")
                                Text("Shuffle")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(palette.surface)
                            .foregroundColor(palette.text)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(palette.separator, lineWidth: 0.6)
                            )
                        }
                        .disabled(songs.isEmpty)
                    }
                    .padding(.horizontal, 16)
                    
                    // Songs List
                    if songs.isEmpty {
                        VStack(spacing: 12) {
                            Text("This playlist has no songs")
                                .font(.subheadline)
                                .foregroundColor(palette.secondary)
                            
                            Button {
                                showAddSongsSheet = true
                            } label: {
                                Text("Add Songs")
                                    .fontWeight(.semibold)
                                    .foregroundColor(palette.accent)
                            }
                        }
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                                SongRowView(
                                    song: song,
                                    palette: palette,
                                    isCurrent: player.currentSong?.id == song.id,
                                    isPlaying: player.state.isPlaying,
                                    onPlay: {
                                        player.playSongs(songs, startIndex: index, shuffle: false)
                                    },
                                    onMenu: {
                                        selectedSongForMenu = song
                                    }
                                )
                                
                                if index < songs.count - 1 {
                                    Divider()
                                        .padding(.leading, 74)
                                        .opacity(0.4)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .background(palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(palette.separator, lineWidth: 0.6)
                        )
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer()
                        .frame(height: 140)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showAddSongsSheet = true
                    } label: {
                        Label("Add Songs", systemImage: "plus")
                    }
                    
                    Button {
                        showCoverSheet = true
                    } label: {
                        Label("Change Cover", systemImage: "photo")
                    }
                    
                    Button {
                        showRenameSheet = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    
                    Button {
                        Task {
                            if let zip = try? await PlaylistArchiveService.shared.exportPlaylist(playlist: currentPlaylist, songs: songs) {
                                exportZipURL = zip
                                showShareExport = true
                            }
                        }
                    } label: {
                        Label("Export Playlist", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive) {
                        store.deletePlaylist(id: currentPlaylist.id)
                        dismiss()
                    } label: {
                        Label("Delete Playlist", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(palette.accent)
                }
            }
        }
        .sheet(isPresented: $showAddSongsSheet) {
            AddSongsSheet(playlistId: currentPlaylist.id, palette: palette)
        }
        .sheet(isPresented: $showRenameSheet) {
            RenamePlaylistSheet(playlistId: currentPlaylist.id, currentName: currentPlaylist.name, palette: palette)
        }
        .sheet(isPresented: $showCoverSheet) {
            PlaylistCoverSheet(playlistId: currentPlaylist.id, palette: palette)
        }
        .sheet(isPresented: $showShareExport) {
            if let zip = exportZipURL {
                ShareSheet(items: [zip])
            }
        }
        .sheet(item: $selectedSongForMenu) { song in
            SongActionMenuSheet(song: song, palette: palette)
                .presentationDetents([.medium, .large])
        }
    }
}

public struct ShareSheet: UIViewControllerRepresentable {
    public let items: [Any]
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

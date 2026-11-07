import SwiftUI

public struct AlbumsView: View {
    @ObservedObject var store = LibraryStore.shared
    public let palette: LiquidPalette
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    public var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(store.albums) { album in
                        NavigationLink {
                            AlbumDetailView(album: album, palette: palette)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                ArtworkImageView(song: album.representativeCoverSong, size: 165, cornerRadius: 14)
                                    .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(album.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(palette.text)
                                        .lineLimit(1)
                                    
                                    Text(album.artist)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(palette.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 140)
            }
        }
        .navigationTitle("Albums")
    }
}

public struct AlbumDetailView: View {
    public let album: Album
    public let palette: LiquidPalette
    @ObservedObject var player = AudioPlayerService.shared
    @State private var selectedSongForMenu: Song?
    
    public var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header Artwork & Info
                    VStack(spacing: 12) {
                        ArtworkImageView(song: album.representativeCoverSong, size: 200, cornerRadius: 18)
                            .shadow(color: Color.black.opacity(0.25), radius: 14, x: 0, y: 8)
                        
                        Text(album.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(palette.text)
                            .multilineTextAlignment(.center)
                        
                        Text("\(album.artist) • \(album.songs.count) songs")
                            .font(.subheadline)
                            .foregroundColor(palette.secondary)
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
                    
                    // Buttons
                    HStack(spacing: 12) {
                        Button {
                            player.playSongs(album.songs, startIndex: 0, shuffle: false)
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
                        
                        Button {
                            player.playSongs(album.songs, startIndex: 0, shuffle: true)
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
                    }
                    .padding(.horizontal, 16)
                    
                    // Songs
                    LazyVStack(spacing: 2) {
                        ForEach(Array(album.songs.enumerated()), id: \.element.id) { index, song in
                            SongRowView(
                                song: song,
                                palette: palette,
                                isCurrent: player.currentSong?.id == song.id,
                                isPlaying: player.state.isPlaying,
                                onPlay: {
                                    player.playSongs(album.songs, startIndex: index, shuffle: false)
                                },
                                onMenu: {
                                    selectedSongForMenu = song
                                }
                            )
                            
                            if index < album.songs.count - 1 {
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
                    
                    Spacer()
                        .frame(height: 140)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSongForMenu) { song in
            SongActionMenuSheet(song: song, palette: palette)
                .presentationDetents([.medium, .large])
        }
    }
}

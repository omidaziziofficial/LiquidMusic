import SwiftUI

public struct ArtistsView: View {
    @ObservedObject var store = LibraryStore.shared
    public let palette: LiquidPalette
    
    public var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(store.artists) { artist in
                        NavigationLink {
                            ArtistDetailView(artist: artist, palette: palette)
                        } label: {
                            HStack(spacing: 14) {
                                // Circular artist avatar
                                ArtworkImageView(song: artist.representativeCoverSong, size: 54, cornerRadius: 27)
                                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(artist.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(palette.text)
                                        .lineLimit(1)
                                    
                                    Text("\(artist.songs.count) songs • \(artist.albumCount) albums")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(palette.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(palette.tertiary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(palette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(palette.separator, lineWidth: 0.6)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 140)
            }
        }
        .navigationTitle("Artists")
    }
}

public struct ArtistDetailView: View {
    public let artist: Artist
    public let palette: LiquidPalette
    @ObservedObject var player = AudioPlayerService.shared
    @State private var selectedSongForMenu: Song?
    
    public var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header Circular Artwork & Info
                    VStack(spacing: 12) {
                        ArtworkImageView(song: artist.representativeCoverSong, size: 160, cornerRadius: 80)
                            .shadow(color: Color.black.opacity(0.25), radius: 14, x: 0, y: 8)
                        
                        Text(artist.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(palette.text)
                        
                        Text("\(artist.songs.count) songs • \(artist.albumCount) albums")
                            .font(.subheadline)
                            .foregroundColor(palette.secondary)
                    }
                    .padding(.top, 10)
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button {
                            player.playSongs(artist.songs, startIndex: 0, shuffle: false)
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
                            player.playSongs(artist.songs, startIndex: 0, shuffle: true)
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
                        ForEach(Array(artist.songs.enumerated()), id: \.element.id) { index, song in
                            SongRowView(
                                song: song,
                                palette: palette,
                                isCurrent: player.currentSong?.id == song.id,
                                isPlaying: player.state.isPlaying,
                                onPlay: {
                                    player.playSongs(artist.songs, startIndex: index, shuffle: false)
                                },
                                onMenu: {
                                    selectedSongForMenu = song
                                }
                            )
                            
                            if index < artist.songs.count - 1 {
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

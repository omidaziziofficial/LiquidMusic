import SwiftUI

public struct CollectionDetailView: View {
    public let type: CollectionType
    public let palette: LiquidPalette
    @ObservedObject var store = LibraryStore.shared
    @ObservedObject var player = AudioPlayerService.shared
    
    @State private var selectedSongForMenu: Song?
    
    public var songs: [Song] {
        store.songsFor(collection: type)
    }
    
    public var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Header card
                    VStack(spacing: 8) {
                        Image(systemName: type.icon)
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(palette.accent)
                        
                        Text(type.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(palette.text)
                        
                        Text("\(songs.count) songs")
                            .font(.subheadline)
                            .foregroundColor(palette.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(palette.separator, lineWidth: 0.6)
                    )
                    .padding(.horizontal, 16)
                    
                    // Action Buttons
                    if !songs.isEmpty {
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
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Songs
                    if songs.isEmpty {
                        Text("No songs in this collection yet.")
                            .font(.subheadline)
                            .foregroundColor(palette.secondary)
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
        .navigationTitle(type.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSongForMenu) { song in
            SongActionMenuSheet(song: song, palette: palette)
                .presentationDetents([.medium, .large])
        }
    }
}

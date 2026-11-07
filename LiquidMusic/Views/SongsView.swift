import SwiftUI

public struct SongsView: View {
    @ObservedObject var store = LibraryStore.shared
    @ObservedObject var player = AudioPlayerService.shared
    public let palette: LiquidPalette
    
    @State private var searchText: String = ""
    @State private var showSortSheet: Bool = false
    @State private var selectedSongForMenu: Song?
    
    public var filteredSongs: [Song] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return store.songs
        } else {
            let q = searchText.lowercased()
            return store.songs.filter {
                $0.title.lowercased().contains(q) ||
                $0.artist.lowercased().contains(q) ||
                $0.album.lowercased().contains(q)
            }
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                palette.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Action Buttons: Play All & Shuffle
                        if !store.songs.isEmpty {
                            HStack(spacing: 12) {
                                Button {
                                    player.playSongs(filteredSongs, startIndex: 0, shuffle: false)
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
                                    player.playSongs(filteredSongs, startIndex: 0, shuffle: true)
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
                            .padding(.top, 8)
                        }
                        
                        // Songs List
                        if filteredSongs.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "music.note")
                                    .font(.system(size: 48))
                                    .foregroundColor(palette.tertiary)
                                Text("No Songs Found")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(palette.text)
                                Text("Add music to your device or rescan your library.")
                                    .font(.subheadline)
                                    .foregroundColor(palette.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 60)
                            .padding(.horizontal, 32)
                        } else {
                            LazyVStack(spacing: 2) {
                                ForEach(Array(filteredSongs.enumerated()), id: \.element.id) { index, song in
                                    SongRowView(
                                        song: song,
                                        palette: palette,
                                        isCurrent: player.currentSong?.id == song.id,
                                        isPlaying: player.state.isPlaying,
                                        onPlay: {
                                            player.playSongs(filteredSongs, startIndex: index, shuffle: false)
                                        },
                                        onMenu: {
                                            selectedSongForMenu = song
                                        }
                                    )
                                    
                                    if index < filteredSongs.count - 1 {
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
                        
                        // Bottom Padding for MiniPlayer and TabBar
                        Spacer()
                            .frame(height: 140)
                    }
                }
                .refreshable {
                    await store.rescanLibrary()
                }
            }
            .navigationTitle("Songs")
            .searchable(text: $searchText, prompt: "Search in songs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSortSheet = true
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(palette.accent)
                    }
                }
            }
            .sheet(isPresented: $showSortSheet) {
                SortSheetView(currentOrder: $store.settings.sortOrder, palette: palette)
            }
            .sheet(item: $selectedSongForMenu) { song in
                SongActionMenuSheet(song: song, palette: palette)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

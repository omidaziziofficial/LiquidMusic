import SwiftUI

public struct FoldersView: View {
    @ObservedObject var store = LibraryStore.shared
    public let palette: LiquidPalette
    
    public var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(store.folders, id: \.self) { folder in
                        let songsInFolder = store.songs.filter { $0.folder == folder }
                        NavigationLink {
                            FolderDetailView(folderName: folder, songs: songsInFolder, palette: palette)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(palette.accent)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(folder)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(palette.text)
                                        .lineLimit(1)
                                    
                                    Text("\(songsInFolder.count) songs")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(palette.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(palette.tertiary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
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
        .navigationTitle("Folders")
    }
}

public struct FolderDetailView: View {
    public let folderName: String
    public let songs: [Song]
    public let palette: LiquidPalette
    @ObservedObject var player = AudioPlayerService.shared
    @State private var selectedSongForMenu: Song?
    
    public var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
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
                        .padding(.top, 8)
                    }
                    
                    // Song List
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
                    
                    Spacer()
                        .frame(height: 140)
                }
            }
        }
        .navigationTitle(folderName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSongForMenu) { song in
            SongActionMenuSheet(song: song, palette: palette)
                .presentationDetents([.medium, .large])
        }
    }
}

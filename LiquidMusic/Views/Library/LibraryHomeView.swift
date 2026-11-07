import SwiftUI

public struct LibraryHomeView: View {
    @ObservedObject var store = LibraryStore.shared
    @ObservedObject var player = AudioPlayerService.shared
    public let palette: LiquidPalette
    
    public var body: some View {
        NavigationStack {
            ZStack {
                palette.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Section 1: Core Navigation Items
                        VStack(spacing: 0) {
                            NavigationLink {
                                PlaylistsView(palette: palette)
                            } label: {
                                libraryRow(icon: "music.note.list", title: "Playlists", count: store.playlists.count)
                            }
                            Divider().padding(.leading, 56)
                            
                            NavigationLink {
                                ArtistsView(palette: palette)
                            } label: {
                                libraryRow(icon: "music.mic", title: "Artists", count: store.artists.count)
                            }
                            Divider().padding(.leading, 56)
                            
                            NavigationLink {
                                AlbumsView(palette: palette)
                            } label: {
                                libraryRow(icon: "square.stack", title: "Albums", count: store.albums.count)
                            }
                            Divider().padding(.leading, 56)
                            
                            NavigationLink {
                                FoldersView(palette: palette)
                            } label: {
                                libraryRow(icon: "folder", title: "Folders", count: store.folders.count)
                            }
                        }
                        .background(palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(palette.separator, lineWidth: 0.6)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        
                        // Section 2: Smart Collections
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Collections")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(palette.text)
                                .padding(.horizontal, 18)
                            
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                                ForEach(CollectionType.allCases) { type in
                                    NavigationLink {
                                        CollectionDetailView(type: type, palette: palette)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Image(systemName: type.icon)
                                                .font(.system(size: 24, weight: .semibold))
                                                .foregroundColor(palette.accent)
                                            
                                            Text(type.title)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(palette.text)
                                            
                                            Text("\(store.songsFor(collection: type).count) songs")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(palette.secondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(14)
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
                        }
                        
                        // Section 3: Recently Played
                        let recentSongs = Array(store.songsFor(collection: .recent).prefix(10))
                        if !recentSongs.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Recently Played")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(palette.text)
                                    .padding(.horizontal, 18)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 14) {
                                        ForEach(recentSongs) { song in
                                            Button {
                                                player.playSongs([song])
                                            } label: {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    ArtworkImageView(song: song, size: 120, cornerRadius: 14)
                                                        .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
                                                    
                                                    Text(song.title)
                                                        .font(.system(size: 13, weight: .semibold))
                                                        .foregroundColor(palette.text)
                                                        .lineLimit(1)
                                                    
                                                    Text(song.artist)
                                                        .font(.system(size: 11, weight: .regular))
                                                        .foregroundColor(palette.secondary)
                                                        .lineLimit(1)
                                                }
                                                .frame(width: 120)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        
                        Spacer()
                            .frame(height: 140)
                    }
                }
            }
            .navigationTitle("Library")
        }
    }
    
    private func libraryRow(icon: String, title: String, count: Int) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(palette.accent)
                .frame(width: 28)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(palette.text)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(palette.tertiary)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(palette.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

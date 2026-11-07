import SwiftUI

public struct SearchView: View {
    @ObservedObject var store = LibraryStore.shared
    @ObservedObject var player = AudioPlayerService.shared
    public let palette: LiquidPalette
    
    @State private var query: String = ""
    @State private var recentSearches: [String] = []
    @State private var selectedSongForMenu: Song?
    
    private var matchingSongs: [Song] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let q = query.lowercased()
        return store.songs.filter {
            $0.title.lowercased().contains(q) ||
            $0.artist.lowercased().contains(q) ||
            $0.album.lowercased().contains(q)
        }
    }
    
    private var matchingArtists: [Artist] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let q = query.lowercased()
        return store.artists.filter { $0.name.lowercased().contains(q) }
    }
    
    private var matchingAlbums: [Album] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let q = query.lowercased()
        return store.albums.filter { $0.name.lowercased().contains(q) || $0.artist.lowercased().contains(q) }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                palette.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if query.trimmingCharacters(in: .whitespaces).isEmpty {
                            // Recent searches
                            if !recentSearches.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("Recent Searches")
                                            .font(.headline)
                                            .foregroundColor(palette.text)
                                        Spacer()
                                        Button("Clear") {
                                            recentSearches.removeAll()
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(palette.accent)
                                    }
                                    .padding(.horizontal, 16)
                                    
                                    ForEach(recentSearches, id: \.self) { term in
                                        Button {
                                            query = term
                                        } label: {
                                            HStack {
                                                Image(systemName: "clock")
                                                    .foregroundColor(palette.tertiary)
                                                Text(term)
                                                    .foregroundColor(palette.text)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                        }
                                    }
                                }
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 48))
                                        .foregroundColor(palette.tertiary)
                                    Text("Search Your Music")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(palette.text)
                                    Text("Find songs, artists, and albums in your library.")
                                        .font(.subheadline)
                                        .foregroundColor(palette.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 80)
                            }
                        } else if matchingSongs.isEmpty && matchingArtists.isEmpty && matchingAlbums.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "questionmark.folder")
                                    .font(.system(size: 48))
                                    .foregroundColor(palette.tertiary)
                                Text("No Results")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(palette.text)
                                Text("No matches found for \"\(query)\".")
                                    .font(.subheadline)
                                    .foregroundColor(palette.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                        } else {
                            // Top Result Card
                            if let topSong = matchingSongs.first {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Top Result")
                                        .font(.headline)
                                        .foregroundColor(palette.text)
                                        .padding(.horizontal, 16)
                                    
                                    Button {
                                        player.playSongs([topSong])
                                        recordSearch(query)
                                    } label: {
                                        HStack(spacing: 14) {
                                            ArtworkImageView(song: topSong, size: 68, cornerRadius: 14)
                                                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(topSong.title)
                                                    .font(.title3)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(palette.text)
                                                    .lineLimit(1)
                                                
                                                Text("Song • \(topSong.artist)")
                                                    .font(.subheadline)
                                                    .foregroundColor(palette.secondary)
                                                    .lineLimit(1)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 38))
                                                .foregroundColor(palette.accent)
                                        }
                                        .padding(14)
                                        .background(palette.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .strokeBorder(palette.separator, lineWidth: 0.6)
                                        )
                                        .padding(.horizontal, 16)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            // Songs
                            if !matchingSongs.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Songs")
                                        .font(.headline)
                                        .foregroundColor(palette.text)
                                        .padding(.horizontal, 16)
                                    
                                    LazyVStack(spacing: 2) {
                                        ForEach(Array(matchingSongs.prefix(15).enumerated()), id: \.element.id) { index, song in
                                            SongRowView(
                                                song: song,
                                                palette: palette,
                                                isCurrent: player.currentSong?.id == song.id,
                                                isPlaying: player.state.isPlaying,
                                                onPlay: {
                                                    player.playSongs(matchingSongs, startIndex: index, shuffle: false)
                                                    recordSearch(query)
                                                },
                                                onMenu: {
                                                    selectedSongForMenu = song
                                                }
                                            )
                                            
                                            if index < min(14, matchingSongs.count - 1) {
                                                Divider().padding(.leading, 74).opacity(0.4)
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
                            }
                            
                            // Artists
                            if !matchingArtists.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Artists")
                                        .font(.headline)
                                        .foregroundColor(palette.text)
                                        .padding(.horizontal, 16)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 14) {
                                            ForEach(matchingArtists) { artist in
                                                NavigationLink {
                                                    ArtistDetailView(artist: artist, palette: palette)
                                                } label: {
                                                    VStack(spacing: 6) {
                                                        ArtworkImageView(song: artist.representativeCoverSong, size: 80, cornerRadius: 40)
                                                        Text(artist.name)
                                                            .font(.system(size: 13, weight: .semibold))
                                                            .foregroundColor(palette.text)
                                                            .lineLimit(1)
                                                    }
                                                    .frame(width: 80)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                            }
                            
                            // Albums
                            if !matchingAlbums.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Albums")
                                        .font(.headline)
                                        .foregroundColor(palette.text)
                                        .padding(.horizontal, 16)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 14) {
                                            ForEach(matchingAlbums) { album in
                                                NavigationLink {
                                                    AlbumDetailView(album: album, palette: palette)
                                                } label: {
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        ArtworkImageView(song: album.representativeCoverSong, size: 110, cornerRadius: 12)
                                                        Text(album.name)
                                                            .font(.system(size: 13, weight: .semibold))
                                                            .foregroundColor(palette.text)
                                                            .lineLimit(1)
                                                        Text(album.artist)
                                                            .font(.system(size: 11, weight: .regular))
                                                            .foregroundColor(palette.secondary)
                                                            .lineLimit(1)
                                                    }
                                                    .frame(width: 110)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                            }
                        }
                        
                        Spacer().frame(height: 140)
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Artists, Songs, Albums")
            .sheet(item: $selectedSongForMenu) { song in
                SongActionMenuSheet(song: song, palette: palette)
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    private func recordSearch(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !recentSearches.contains(trimmed) {
            recentSearches.insert(trimmed, at: 0)
            if recentSearches.count > 10 {
                recentSearches.removeLast()
            }
        }
    }
}

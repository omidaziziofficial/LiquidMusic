import Foundation
import SwiftUI
import Combine
import MediaPlayer
import AVFoundation

@MainActor
public final class LibraryStore: ObservableObject {
    public static let shared = LibraryStore()
    
    @Published public var songs: [Song] = []
    @Published public var songsMap: [Int64: Song] = [:]
    @Published public var albums: [Album] = []
    @Published public var artists: [Artist] = []
    @Published public var playlists: [Playlist] = []
    @Published public var favorites: Set<Int64> = []
    @Published public var playCounts: [Int64: Int] = [:]
    @Published public var lastPlayed: [Int64: Int64] = [:]
    @Published public var overrides: [Int64: SongOverride] = [:]
    
    @Published public var settings: AppSettings = AppSettings()
    @Published public var isScanning: Bool = false
    @Published public var folders: [String] = []
    
    private let fileManager = FileManager.default
    private var libraryFileURL: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("library.json")
    }
    
    public var coversDirectoryURL: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("covers")
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    public var musicDirectoryURL: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Music")
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private init() {
        loadSettings()
        loadLibraryData()
        Task {
            await rescanLibrary()
        }
    }
    
    // MARK: - Settings Persistence
    public func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "LiquidMusic_AppSettings"),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = AppSettings()
        }
    }
    
    public func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "LiquidMusic_AppSettings")
        }
    }
    
    public func updateSettings(_ transform: (inout AppSettings) -> Void) {
        transform(&settings)
        saveSettings()
    }
    
    // MARK: - Library Data Persistence (library.json)
    public func loadLibraryData() {
        guard fileManager.fileExists(atPath: libraryFileURL.path),
              let data = try? Data(contentsOf: libraryFileURL),
              let decoded = try? JSONDecoder().decode(LibraryData.self, from: data) else {
            return
        }
        self.favorites = decoded.favorites
        self.playlists = decoded.playlists
        self.playCounts = decoded.playCounts
        self.lastPlayed = decoded.lastPlayed
        self.overrides = decoded.overrides
    }
    
    public func saveLibraryData() {
        let dataObj = LibraryData(
            favorites: favorites,
            playlists: playlists,
            playCounts: playCounts,
            lastPlayed: lastPlayed,
            overrides: overrides
        )
        if let encoded = try? JSONEncoder().encode(dataObj) {
            try? encoded.write(to: libraryFileURL, options: .atomic)
        }
    }
    
    // MARK: - Library Scanning
    public func rescanLibrary() async {
        isScanning = true
        defer { isScanning = false }
        
        var loadedSongs: [Song] = []
        var detectedFolders = Set<String>()
        
        // 1. Scan app's internal Music & Documents folder
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let searchDirectories = [docs, musicDirectoryURL]
        let audioExtensions = ["mp3", "m4a", "wav", "flac", "aac", "ogg"]
        
        for dir in searchDirectories {
            if let enumerator = fileManager.enumerator(at: dir, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey], options: [.skipsHiddenFiles]) {
                for case let fileURL as URL in enumerator {
                    if audioExtensions.contains(fileURL.pathExtension.lowercased()) {
                        let folderName = fileURL.deletingLastPathComponent().lastPathComponent
                        detectedFolders.insert(folderName)
                        
                        // Check if folder is excluded by settings
                        if !settings.folders.isEmpty && !settings.folders.contains(folderName) {
                            continue
                        }
                        
                        if let song = extractSongMetadata(from: fileURL, folder: folderName) {
                            // Filter short audio if setting enabled
                            if song.duration >= Int64(settings.minDurationSec * 1000) {
                                loadedSongs.append(song)
                            }
                        }
                    }
                }
            }
        }
        
        // 2. Scan Apple Music Media Library if authorized
        let status = MPMediaLibrary.authorizationStatus()
        if status == .authorized {
            let query = MPMediaQuery.songs()
            if let items = query.items {
                for item in items {
                    if let assetURL = item.assetURL {
                        let durationMs = Int64(item.playbackDuration * 1000)
                        if durationMs >= Int64(settings.minDurationSec * 1000) {
                            let songId = Int64(item.persistentID)
                            let song = Song(
                                id: songId,
                                uri: assetURL.absoluteString,
                                title: item.title ?? "Unknown Title",
                                artist: item.artist ?? "Unknown Artist",
                                album: item.albumTitle ?? "Unknown Album",
                                albumId: Int64(item.albumPersistentID),
                                duration: durationMs,
                                size: 0,
                                dateAdded: Int64(((item.value(forProperty: MPMediaItemPropertyDateAdded) as? Date) ?? Date()).timeIntervalSince1970),
                                path: assetURL.path,
                                folder: "Apple Music",
                                track: item.albumTrackNumber,
                                year: 0,
                                mimeType: "audio/mpeg"
                            )
                            loadedSongs.append(song)
                            detectedFolders.insert("Apple Music")
                        }
                    }
                }
            }
        }
        
        // Apply Overrides (from tag editing)
        for i in 0..<loadedSongs.count {
            let id = loadedSongs[i].id
            if let ov = overrides[id] {
                if let t = ov.title { loadedSongs[i].title = t }
                if let a = ov.artist { loadedSongs[i].artist = a }
                if let al = ov.album { loadedSongs[i].album = al }
                if let cp = ov.coverPath { loadedSongs[i].coverPath = cp }
                loadedSongs[i].coverVersion = ov.coverVersion
            }
        }
        
        // Apply Sort Order
        loadedSongs = sortSongs(loadedSongs, order: settings.sortOrder)
        
        self.songs = loadedSongs
        self.folders = Array(detectedFolders).sorted()
        
        var map: [Int64: Song] = [:]
        for s in loadedSongs {
            map[s.id] = s
        }
        self.songsMap = map
        
        rebuildAlbumsAndArtists()
    }
    
    private func extractSongMetadata(from url: URL, folder: String) -> Song? {
        let asset = AVURLAsset(url: url)
        let id = Int64(abs(url.path.hashValue))
        var title = url.deletingPathExtension().lastPathComponent
        var artist = "Unknown Artist"
        var album = "Unknown Album"
        var track = 0
        var year = 0
        let durationMs = Int64(CMTimeGetSeconds(asset.duration) * 1000)
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        let size = (attributes?[.size] as? Int64) ?? 0
        let dateAdded = (attributes?[.creationDate] as? Date)?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
        
        for item in asset.commonMetadata {
            guard let key = item.commonKey?.rawValue else { continue }
            if key == AVMetadataKey.commonKeyTitle.rawValue, let str = item.stringValue {
                title = str
            } else if key == AVMetadataKey.commonKeyArtist.rawValue, let str = item.stringValue {
                artist = str
            } else if key == AVMetadataKey.commonKeyAlbumName.rawValue, let str = item.stringValue {
                album = str
            }
        }
        
        return Song(
            id: id,
            uri: url.absoluteString,
            title: title,
            artist: artist,
            album: album,
            albumId: Int64(abs(album.hashValue)),
            duration: durationMs,
            size: size,
            dateAdded: Int64(dateAdded),
            path: url.path,
            folder: folder,
            track: track,
            year: year,
            mimeType: "audio/" + url.pathExtension.lowercased()
        )
    }
    
    // MARK: - Albums & Artists Rebuilding
    public func rebuildAlbumsAndArtists() {
        // Group Albums
        var albumGroups: [String: [Song]] = [:]
        for song in songs {
            let cleanArtist = cleanArtistName(song.artist)
            let key = song.album.lowercased() + "|" + (song.album == "Unknown Album" ? cleanArtist : "")
            albumGroups[key, default: []].append(song)
        }
        
        self.albums = albumGroups.map { (key, groupSongs) in
            let first = groupSongs.first!
            let sortedSongs = groupSongs.sorted { $0.track < $1.track }
            return Album(key: key, name: first.album, artist: first.artist, songs: sortedSongs)
        }.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        
        // Group Artists
        var artistGroups: [String: [Song]] = [:]
        for song in songs {
            let primaryArtist = cleanArtistName(song.artist)
            artistGroups[primaryArtist, default: []].append(song)
        }
        
        self.artists = artistGroups.map { (name, groupSongs) in
            let uniqueAlbums = Set(groupSongs.map { $0.album }).count
            return Artist(name: name, songs: groupSongs, albumCount: uniqueAlbums)
        }.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
    
    public func cleanArtistName(_ raw: String) -> String {
        let separators = [" feat.", " ft.", " Feat.", " Ft.", " & ", ", ", " x ", "/", ";"]
        var cleaned = raw
        for sep in separators {
            if let range = cleaned.range(of: sep, options: .caseInsensitive) {
                cleaned = String(cleaned[..<range.lowerBound])
            }
        }
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? raw : trimmed
    }
    
    // MARK: - Sorting Songs
    public func sortSongs(_ list: [Song], order: SortOrder) -> [Song] {
        switch order {
        case .dateAdded:
            return list.sorted { $0.dateAdded > $1.dateAdded }
        case .nameAZ:
            return list.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .nameZA:
            return list.sorted { $0.title.localizedCompare($1.title) == .orderedDescending }
        case .sizeDesc:
            return list.sorted { $0.size > $1.size }
        case .sizeAsc:
            return list.sorted { $0.size < $1.size }
        case .mostPlayed:
            return list.sorted { (playCounts[$0.id] ?? 0) > (playCounts[$1.id] ?? 0) }
        case .duration:
            return list.sorted { $0.duration > $1.duration }
        }
    }
    
    // MARK: - Favorites
    public func toggleFavorite(songId: Int64) {
        if favorites.contains(songId) {
            favorites.remove(songId)
        } else {
            favorites.insert(songId)
        }
        saveLibraryData()
    }
    
    public func isFavorite(songId: Int64) -> Bool {
        favorites.contains(songId)
    }
    
    // MARK: - Play Tracking
    public func recordPlayback(songId: Int64) {
        playCounts[songId, default: 0] += 1
        lastPlayed[songId] = Int64(Date().timeIntervalSince1970 * 1000)
        saveLibraryData()
    }
    
    // MARK: - Playlists CRUD
    public func createPlaylist(name: String, songIds: [Int64] = []) -> Playlist {
        let newPlaylist = Playlist(name: name, songIds: songIds)
        playlists.append(newPlaylist)
        saveLibraryData()
        return newPlaylist
    }
    
    public func deletePlaylist(id: Int64) {
        playlists.removeAll { $0.id == id }
        saveLibraryData()
    }
    
    public func renamePlaylist(id: Int64, newName: String) {
        if let idx = playlists.firstIndex(where: { $0.id == id }) {
            playlists[idx].name = newName
            saveLibraryData()
        }
    }
    
    public func addSongsToPlaylist(playlistId: Int64, songIds: [Int64]) {
        if let idx = playlists.firstIndex(where: { $0.id == playlistId }) {
            for id in songIds {
                if !playlists[idx].songIds.contains(id) {
                    playlists[idx].songIds.append(id)
                }
            }
            saveLibraryData()
        }
    }
    
    public func removeSongFromPlaylist(playlistId: Int64, songId: Int64) {
        if let idx = playlists.firstIndex(where: { $0.id == playlistId }) {
            playlists[idx].songIds.removeAll { $0 == songId }
            saveLibraryData()
        }
    }
    
    public func updatePlaylistCover(playlistId: Int64, mode: Int, songId: Int64? = nil, customPath: String? = nil) {
        if let idx = playlists.firstIndex(where: { $0.id == playlistId }) {
            playlists[idx].coverMode = mode
            playlists[idx].coverSongId = songId
            playlists[idx].coverPath = customPath
            playlists[idx].coverVersion = Int64(Date().timeIntervalSince1970 * 1000)
            saveLibraryData()
        }
    }
    
    // MARK: - Song Tag Overrides
    public func updateSongTags(songId: Int64, title: String?, artist: String?, album: String?, customCoverImage: UIImage?) {
        var ov = overrides[songId] ?? SongOverride()
        if let t = title { ov.title = t }
        if let a = artist { ov.artist = a }
        if let al = album { ov.album = al }
        
        if let img = customCoverImage, let data = img.jpegData(compressionQuality: 0.85) {
            let filename = "cover_\(songId)_\(Int(Date().timeIntervalSince1970)).jpg"
            let targetURL = coversDirectoryURL.appendingPathComponent(filename)
            try? data.write(to: targetURL)
            ov.coverPath = targetURL.path
            ov.coverVersion = Int64(Date().timeIntervalSince1970 * 1000)
        }
        
        overrides[songId] = ov
        saveLibraryData()
        
        // Update live song
        if let idx = songs.firstIndex(where: { $0.id == songId }) {
            if let t = ov.title { songs[idx].title = t }
            if let a = ov.artist { songs[idx].artist = a }
            if let al = ov.album { songs[idx].album = al }
            if let cp = ov.coverPath { songs[idx].coverPath = cp }
            songs[idx].coverVersion = ov.coverVersion
            songsMap[songId] = songs[idx]
        }
        rebuildAlbumsAndArtists()
    }
    
    // MARK: - Collections Retrieval
    public func songsFor(collection: CollectionType) -> [Song] {
        switch collection {
        case .favorites:
            return songs.filter { favorites.contains($0.id) }
        case .recent:
            let sortedByLast = lastPlayed.sorted { $0.value > $1.value }.map { $0.key }
            return sortedByLast.compactMap { songsMap[$0] }
        case .mostPlayed:
            let sortedByCount = playCounts.filter { $0.value > 0 }.sorted { $0.value > $1.value }.map { $0.key }
            return sortedByCount.compactMap { songsMap[$0] }
        case .recentlyAdded:
            return songs.sorted { $0.dateAdded > $1.dateAdded }
        }
    }
}

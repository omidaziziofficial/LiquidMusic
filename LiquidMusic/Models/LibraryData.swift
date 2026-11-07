import Foundation

public struct SongOverride: Codable, Hashable {
    public var title: String?
    public var artist: String?
    public var album: String?
    public var coverPath: String?
    public var coverVersion: Int64
    
    public init(
        title: String? = nil,
        artist: String? = nil,
        album: String? = nil,
        coverPath: String? = nil,
        coverVersion: Int64 = 0
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.coverPath = coverPath
        self.coverVersion = coverVersion
    }
}

public struct LibraryData: Codable {
    public var favorites: Set<Int64>
    public var playlists: [Playlist]
    public var playCounts: [Int64: Int]
    public var lastPlayed: [Int64: Int64]
    public var overrides: [Int64: SongOverride]
    
    public init(
        favorites: Set<Int64> = [],
        playlists: [Playlist] = [],
        playCounts: [Int64: Int] = [:],
        lastPlayed: [Int64: Int64] = [:],
        overrides: [Int64: SongOverride] = [:]
    ) {
        self.favorites = favorites
        self.playlists = playlists
        self.playCounts = playCounts
        self.lastPlayed = lastPlayed
        self.overrides = overrides
    }
}

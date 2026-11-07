import Foundation

public struct Album: Identifiable, Hashable {
    public let key: String
    public let name: String
    public let artist: String
    public var songs: [Song]
    
    public var id: String { key }
    
    public init(key: String, name: String, artist: String, songs: [Song]) {
        self.key = key
        self.name = name
        self.artist = artist
        self.songs = songs
    }
    
    public var totalDuration: Int64 {
        songs.reduce(0) { $0 + $1.duration }
    }
    
    public var representativeCoverSong: Song? {
        songs.first
    }
}

public struct Artist: Identifiable, Hashable {
    public let name: String
    public var songs: [Song]
    public var albumCount: Int
    
    public var id: String { name }
    
    public init(name: String, songs: [Song], albumCount: Int = 1) {
        self.name = name
        self.songs = songs
        self.albumCount = albumCount
    }
    
    public var representativeCoverSong: Song? {
        songs.first
    }
}

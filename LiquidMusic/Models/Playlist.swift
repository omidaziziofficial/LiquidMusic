import Foundation

public struct Playlist: Identifiable, Hashable, Codable {
    public let id: Int64
    public var name: String
    public var songIds: [Int64]
    public var created: Int64
    public var coverMode: Int // 0 = 4-mix, 1 = single song, 2 = custom image
    public var coverSongId: Int64?
    public var coverPath: String?
    public var coverVersion: Int64
    
    public init(
        id: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        name: String,
        songIds: [Int64] = [],
        created: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        coverMode: Int = 0,
        coverSongId: Int64? = nil,
        coverPath: String? = nil,
        coverVersion: Int64 = 0
    ) {
        self.id = id
        self.name = name
        self.songIds = songIds
        self.created = created
        self.coverMode = coverMode
        self.coverSongId = coverSongId
        self.coverPath = coverPath
        self.coverVersion = coverVersion
    }
}

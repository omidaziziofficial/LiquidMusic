import Foundation
import SwiftUI

public struct Song: Identifiable, Hashable, Codable {
    public let id: Int64
    public var uri: String
    public var title: String
    public var artist: String
    public var album: String
    public var albumId: Int64
    public var duration: Int64 // in milliseconds
    public var size: Int64 // in bytes
    public var dateAdded: Int64 // unix timestamp in seconds
    public var path: String
    public var folder: String
    public var track: Int
    public var year: Int
    public var mimeType: String
    public var coverPath: String?
    public var coverVersion: Int64
    
    public init(
        id: Int64,
        uri: String,
        title: String,
        artist: String,
        album: String,
        albumId: Int64 = 0,
        duration: Int64 = 0,
        size: Int64 = 0,
        dateAdded: Int64 = Int64(Date().timeIntervalSince1970),
        path: String = "",
        folder: String = "",
        track: Int = 0,
        year: Int = 0,
        mimeType: String = "audio/mpeg",
        coverPath: String? = nil,
        coverVersion: Int64 = 0
    ) {
        self.id = id
        self.uri = uri
        self.title = title
        self.artist = artist
        self.album = album
        self.albumId = albumId
        self.duration = duration
        self.size = size
        self.dateAdded = dateAdded
        self.path = path
        self.folder = folder
        self.track = track
        self.year = year
        self.mimeType = mimeType
        self.coverPath = coverPath
        self.coverVersion = coverVersion
    }
    
    public var durationSeconds: TimeInterval {
        return TimeInterval(duration) / 1000.0
    }
    
    public var formattedDuration: String {
        let totalSeconds = Int(duration / 1000)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

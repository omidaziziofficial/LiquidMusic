import Foundation
import UniformTypeIdentifiers

public final class PlaylistArchiveService {
    public static let shared = PlaylistArchiveService()
    
    private init() {}
    
    public struct ExportMetadata: Codable {
        public let name: String
        public let created: Int64
        public let songs: [ExportSongItem]
    }
    
    public struct ExportSongItem: Codable {
        public let filename: String
        public let title: String
        public let artist: String
        public let album: String
        public let duration: Int64
    }
    
    public func exportPlaylist(playlist: Playlist, songs: [Song]) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("export_\(playlist.id)")
        try? FileManager.default.removeItem(at: tempDir)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        var songItems: [ExportSongItem] = []
        for song in songs {
            let originalURL = URL(fileURLWithPath: song.path)
            let ext = originalURL.pathExtension.isEmpty ? "mp3" : originalURL.pathExtension
            let cleanFilename = "\(song.artist) - \(song.title).\(ext)"
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "-")
            
            let destURL = tempDir.appendingPathComponent(cleanFilename)
            if FileManager.default.fileExists(atPath: originalURL.path) {
                try? FileManager.default.copyItem(at: originalURL, to: destURL)
            }
            
            songItems.append(ExportSongItem(
                filename: cleanFilename,
                title: song.title,
                artist: song.artist,
                album: song.album,
                duration: song.duration
            ))
        }
        
        let meta = ExportMetadata(name: playlist.name, created: playlist.created, songs: songItems)
        let metaData = try JSONEncoder().encode(meta)
        try metaData.write(to: tempDir.appendingPathComponent("playlist.json"))
        
        let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(playlist.name).zip")
        try? FileManager.default.removeItem(at: zipURL)
        
        var error: NSError?
        NSFileCoordinator().coordinate(readingItemAt: tempDir, options: .forUploading, error: &error) { zipOutputURL in
            try? FileManager.default.copyItem(at: zipOutputURL, to: zipURL)
        }
        
        try? FileManager.default.removeItem(at: tempDir)
        return zipURL
    }
    
    public func importPlaylist(from zipURL: URL) async throws -> Playlist? {
        let tempExtractDir = FileManager.default.temporaryDirectory.appendingPathComponent("import_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempExtractDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempExtractDir) }
        
        // Decompress coordinate
        var error: NSError?
        var extracted = false
        NSFileCoordinator().coordinate(readingItemAt: zipURL, options: .withoutChanges, error: &error) { unzippedURL in
            // Copy contents
            if let enumerator = FileManager.default.enumerator(at: unzippedURL, includingPropertiesForKeys: nil) {
                for case let file as URL in enumerator {
                    let relative = file.path.replacingOccurrences(of: unzippedURL.path, with: "")
                    let target = tempExtractDir.appendingPathComponent(relative)
                    try? FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try? FileManager.default.copyItem(at: file, to: target)
                }
                extracted = true
            }
        }
        
        guard extracted else { return nil }
        let metaFile = tempExtractDir.appendingPathComponent("playlist.json")
        guard let metaData = try? Data(contentsOf: metaFile),
              let meta = try? JSONDecoder().decode(ExportMetadata.self, from: metaData) else {
            return nil
        }
        
        var importedSongIds: [Int64] = []
        let musicDir = await LibraryStore.shared.musicDirectoryURL
        
        for item in meta.songs {
            let sourceFile = tempExtractDir.appendingPathComponent(item.filename)
            let destFile = musicDir.appendingPathComponent(item.filename)
            if FileManager.default.fileExists(atPath: sourceFile.path) {
                try? FileManager.default.copyItem(at: sourceFile, to: destFile)
                let id = Int64(abs(destFile.path.hashValue))
                importedSongIds.append(id)
            }
        }
        
        await LibraryStore.shared.rescanLibrary()
        let playlist = await LibraryStore.shared.createPlaylist(name: meta.name, songIds: importedSongIds)
        return playlist
    }
}

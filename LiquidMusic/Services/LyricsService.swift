import Foundation
import AVFoundation

@MainActor
public final class LyricsService: ObservableObject {
    public static let shared = LyricsService()
    
    @Published public var currentLyrics: Lyrics?
    @Published public var isLoading: Bool = false
    @Published public var searchResults: [String] = []
    
    private let fileManager = FileManager.default
    private var lyricsDir: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("lyrics")
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private var onlineLyricsDir: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("lyrics_online")
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private init() {}
    
    // MARK: - Fetch or Load Lyrics for Song
    public func loadLyrics(for song: Song) async -> Lyrics? {
        // 1. Check local user-edited file
        let localFile = lyricsDir.appendingPathComponent("\(song.id).lrc")
        if let data = try? Data(contentsOf: localFile), let text = String(data: data, encoding: .utf8) {
            let parsed = Lyrics.parse(lrcText: text, source: "local")
            self.currentLyrics = parsed
            return parsed
        }
        
        // 2. Check local online cache
        let cacheFile = onlineLyricsDir.appendingPathComponent("\(song.id).lrc")
        if let data = try? Data(contentsOf: cacheFile), let text = String(data: data, encoding: .utf8) {
            let parsed = Lyrics.parse(lrcText: text, source: "online")
            self.currentLyrics = parsed
            return parsed
        }
        
        // 3. Check embedded tags
        if let embedded = extractEmbeddedLyrics(from: song) {
            let parsed = Lyrics.parse(lrcText: embedded, source: "tag")
            self.currentLyrics = parsed
            return parsed
        }
        
        // 4. Fetch online if auto lyrics enabled
        if LibraryStore.shared.settings.autoLyrics {
            if let online = await fetchOnlineLyrics(for: song) {
                // Cache to online folder
                try? online.raw.write(to: cacheFile, atomically: true, encoding: .utf8)
                self.currentLyrics = online
                return online
            }
        }
        
        self.currentLyrics = nil
        return nil
    }
    
    // MARK: - Embedded Lyrics Extraction
    private func extractEmbeddedLyrics(from song: Song) -> String? {
        guard let url = URL(string: song.uri) ?? URL(fileURLWithPath: song.path) as URL? else { return nil }
        let asset = AVURLAsset(url: url)
        for item in asset.commonMetadata {
            if item.commonKey?.rawValue == "lyrics", let str = item.stringValue {
                return str
            }
        }
        return nil
    }
    
    // MARK: - Online Fetching (LRCLIB + Persian Sites)
    public func fetchOnlineLyrics(for song: Song) async -> Lyrics? {
        isLoading = true
        defer { isLoading = false }
        
        // A. Clean song title (remove (Official Video), [HQ], etc.)
        let cleanTitle = song.title.replacingOccurrences(
            of: "\\s*[(\\[](official|lyrics?|audio|video|hd|hq|remaster(ed)?|explicit)[^)\\]]*[)\\]]",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        
        let cleanArtist = LibraryStore.shared.cleanArtistName(song.artist)
        let durationSec = song.duration / 1000
        
        // 1. Try LRCLIB exact match
        if let encodedTitle = cleanTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let encodedArtist = cleanArtist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            
            var urlString = "https://lrclib.net/api/get?track_name=\(encodedTitle)&artist_name=\(encodedArtist)&duration=\(durationSec)"
            if song.album != "Unknown Album", let encodedAlbum = song.album.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                urlString += "&album_name=\(encodedAlbum)"
            }
            
            if let url = URL(string: urlString),
               let (data, _) = try? await URLSession.shared.data(from: url),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                if let synced = json["syncedLyrics"] as? String, !synced.isEmpty {
                    return Lyrics.parse(lrcText: synced, source: "lrclib")
                } else if let plain = json["plainLyrics"] as? String, !plain.isEmpty {
                    return Lyrics.parse(lrcText: plain, source: "lrclib")
                }
            }
            
            // 2. Try LRCLIB search fallback
            let query = "\(cleanTitle) \(cleanArtist)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let searchURL = URL(string: "https://lrclib.net/api/search?q=\(query)"),
               let (data, _) = try? await URLSession.shared.data(from: searchURL),
               let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                
                for item in list {
                    if let synced = item["syncedLyrics"] as? String, !synced.isEmpty {
                        return Lyrics.parse(lrcText: synced, source: "lrclib")
                    } else if let plain = item["plainLyrics"] as? String, !plain.isEmpty {
                        return Lyrics.parse(lrcText: plain, source: "lrclib")
                    }
                }
            }
        }
        
        // 3. Try Persian music lyrics scraping via DuckDuckGo HTML
        let persianQuery = "متن آهنگ \(cleanTitle) \(cleanArtist)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let ddgURL = URL(string: "https://html.duckduckgo.com/html/?q=\(persianQuery)"),
           let (htmlData, _) = try? await URLSession.shared.data(from: ddgURL),
           let htmlString = String(data: htmlData, encoding: .utf8) {
            
            if let parsed = extractPersianLyrics(from: htmlString) {
                return Lyrics.parse(lrcText: parsed, source: "persian_web")
            }
        }
        
        return nil
    }
    
    private func extractPersianLyrics(from html: String) -> String? {
        let persianDomains = [
            "gahar.ir", "musicsweb.ir", "upmusics.com", "mytehranmusic.com",
            "music-fa.com", "horadi.com", "mokhtalefmusic.com", "nicmusic.net",
            "sevilmusic.com", "yadegarmusic.ir", "melomusic.ir"
        ]
        
        // Simple heuristic: search for Persian lyrics container blocks in HTML snippets
        let pattern = "<(?:div|p)[^>]*class=[\"'][^\"']*(?:lyric|text|matn)[^\"']*[\"'][^>]*>(.*?)</(?:div|p)>"
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let matches = regex.matches(in: html, range: NSRange(location: 0, length: html.utf16.count))
            for match in matches {
                if let range = Range(match.range(at: 1), in: html) {
                    var text = String(html[range])
                    text = text.replacingOccurrences(of: "<br/?>", with: "\n", options: .regularExpression)
                    text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                    text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if text.count > 50 {
                        return text
                    }
                }
            }
        }
        return nil
    }
    
    // MARK: - Save Custom Lyrics
    public func saveLyrics(for song: Song, text: String) {
        let localFile = lyricsDir.appendingPathComponent("\(song.id).lrc")
        try? text.write(to: localFile, atomically: true, encoding: .utf8)
        self.currentLyrics = Lyrics.parse(lrcText: text, source: "local")
    }
    
    public func deleteLyrics(for song: Song) {
        let localFile = lyricsDir.appendingPathComponent("\(song.id).lrc")
        let cacheFile = onlineLyricsDir.appendingPathComponent("\(song.id).lrc")
        try? fileManager.removeItem(at: localFile)
        try? fileManager.removeItem(at: cacheFile)
        self.currentLyrics = nil
    }
}

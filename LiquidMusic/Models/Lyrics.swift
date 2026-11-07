import Foundation

public struct LyricLine: Identifiable, Hashable, Codable {
    public var id: Int64 { timeMs }
    public let timeMs: Int64
    public let text: String
    
    public init(timeMs: Int64, text: String) {
        self.timeMs = timeMs
        self.text = text
    }
}

public struct Lyrics: Hashable, Codable {
    public var raw: String
    public var lines: [LyricLine]
    public var synced: Bool
    public var source: String
    
    public init(raw: String, lines: [LyricLine] = [], synced: Bool = false, source: String = "") {
        self.raw = raw
        self.lines = lines
        self.synced = synced
        self.source = source
    }
    
    public static func parse(lrcText: String, source: String = "online") -> Lyrics {
        let pattern = "\\[(\\d{2}):(\\d{2})(?:[.:](\\d{2,3}))?\\](.*)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            let plainLines = lrcText.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .enumerated()
                .map { LyricLine(timeMs: Int64($0.offset * 3000), text: $0.element) }
            return Lyrics(raw: lrcText, lines: plainLines, synced: false, source: source)
        }
        
        var parsedLines: [LyricLine] = []
        let nsString = lrcText as NSString
        let lines = lrcText.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            let matches = regex.matches(in: trimmed, range: NSRange(location: 0, length: trimmed.utf16.count))
            if let match = matches.first {
                let minRange = match.range(at: 1)
                let secRange = match.range(at: 2)
                let msRange = match.range(at: 3)
                let textRange = match.range(at: 4)
                
                let mins = (trimmed as NSString).substring(with: minRange)
                let secs = (trimmed as NSString).substring(with: secRange)
                var ms = "0"
                if msRange.location != NSNotFound {
                    ms = (trimmed as NSString).substring(with: msRange)
                }
                
                let text = (trimmed as NSString).substring(with: textRange).trimmingCharacters(in: .whitespaces)
                
                let minVal = Int64(mins) ?? 0
                let secVal = Int64(secs) ?? 0
                var msVal = Int64(ms) ?? 0
                if ms.count == 2 { msVal *= 10 }
                
                let totalMs = (minVal * 60 + secVal) * 1000 + msVal
                parsedLines.append(LyricLine(timeMs: totalMs, text: text))
            }
        }
        
        parsedLines.sort { $0.timeMs < $1.timeMs }
        let isSynced = !parsedLines.isEmpty
        if !isSynced {
            let plain = lrcText.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .enumerated()
                .map { LyricLine(timeMs: Int64($0.offset * 3000), text: $0.element) }
            return Lyrics(raw: lrcText, lines: plain, synced: false, source: source)
        }
        
        return Lyrics(raw: lrcText, lines: parsedLines, synced: isSynced, source: source)
    }
}

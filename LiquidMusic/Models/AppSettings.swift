import Foundation

public struct AppSettings: Codable, Equatable {
    public var themeMode: ThemeMode
    public var accent: Int
    public var folders: Set<String>
    public var sortOrder: SortOrder
    public var autoLyrics: Bool
    public var reduceTransparency: Bool
    public var minDurationSec: Int
    public var artworkBackground: Bool
    public var fadeOnSleep: Bool
    public var crossfade: Bool
    public var crossfadeSec: Int
    public var voiceControl: Bool
    public var crossfadeManual: Bool
    public var appIcon: Int
    public var swipeCover: Bool
    public var voiceBluetoothMic: Bool
    public var restartOnPrevious: Bool
    public var downloadFolderUri: String?
    public var downloadFolderPath: String?
    
    public init(
        themeMode: ThemeMode = .system,
        accent: Int = 0,
        folders: Set<String> = [],
        sortOrder: SortOrder = .dateAdded,
        autoLyrics: Bool = true,
        reduceTransparency: Bool = false,
        minDurationSec: Int = 30,
        artworkBackground: Bool = true,
        fadeOnSleep: Bool = true,
        crossfade: Bool = false,
        crossfadeSec: Int = 6,
        voiceControl: Bool = false,
        crossfadeManual: Bool = false,
        appIcon: Int = 0,
        swipeCover: Bool = false,
        voiceBluetoothMic: Bool = false,
        restartOnPrevious: Bool = false,
        downloadFolderUri: String? = nil,
        downloadFolderPath: String? = nil
    ) {
        self.themeMode = themeMode
        self.accent = accent
        self.folders = folders
        self.sortOrder = sortOrder
        self.autoLyrics = autoLyrics
        self.reduceTransparency = reduceTransparency
        self.minDurationSec = minDurationSec
        self.artworkBackground = artworkBackground
        self.fadeOnSleep = fadeOnSleep
        self.crossfade = crossfade
        self.crossfadeSec = max(3, min(20, crossfadeSec))
        self.voiceControl = voiceControl
        self.crossfadeManual = crossfadeManual
        self.appIcon = appIcon
        self.swipeCover = swipeCover
        self.voiceBluetoothMic = voiceBluetoothMic
        self.restartOnPrevious = restartOnPrevious
        self.downloadFolderUri = downloadFolderUri
        self.downloadFolderPath = downloadFolderPath
    }
}

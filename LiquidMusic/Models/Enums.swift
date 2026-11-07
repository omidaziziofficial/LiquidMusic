import Foundation
import SwiftUI

// MARK: - Theme Mode
public enum ThemeMode: String, CaseIterable, Codable, Identifiable {
    case system = "SYSTEM"
    case light = "LIGHT"
    case dark = "DARK"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .system: return "Automatic"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

// MARK: - Sort Order
public enum SortOrder: String, CaseIterable, Codable, Identifiable {
    case dateAdded = "DATE_ADDED"
    case nameAZ = "NAME_AZ"
    case nameZA = "NAME_ZA"
    case sizeDesc = "SIZE_DESC"
    case sizeAsc = "SIZE_ASC"
    case mostPlayed = "MOST_PLAYED"
    case duration = "DURATION"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .dateAdded: return "Date Added"
        case .nameAZ: return "Name (A–Z)"
        case .nameZA: return "Name (Z–A)"
        case .sizeDesc: return "Size (Largest)"
        case .sizeAsc: return "Size (Smallest)"
        case .mostPlayed: return "Most Played"
        case .duration: return "Duration"
        }
    }
}

// MARK: - Collection Type
public enum CollectionType: String, CaseIterable, Codable, Identifiable {
    case favorites = "FAVORITES"
    case recent = "RECENT"
    case mostPlayed = "MOST_PLAYED"
    case recentlyAdded = "RECENTLY_ADDED"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .favorites: return "Favorites"
        case .recent: return "Recently Played"
        case .mostPlayed: return "Most Played"
        case .recentlyAdded: return "Recently Added"
        }
    }
    
    public var icon: String {
        switch self {
        case .favorites: return "heart.fill"
        case .recent: return "clock.arrow.circlepath"
        case .mostPlayed: return "chart.bar.fill"
        case .recentlyAdded: return "plus.circle.fill"
        }
    }
}

// MARK: - Repeat Mode
public enum RepeatMode: Int, CaseIterable, Codable {
    case off = 0
    case all = 1
    case one = 2
    
    public var icon: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }
}

// MARK: - Sleep Timer Mode
public enum SleepTimerMode: Equatable {
    case off
    case endOfTrack
    case minutes(Int)
    
    public var title: String {
        switch self {
        case .off: return "Off"
        case .endOfTrack: return "End of Current Song"
        case .minutes(let mins):
            if mins == 60 { return "1 hour" }
            if mins > 60 && mins % 60 == 0 { return "\(mins / 60) hours" }
            return "\(mins) minutes"
        }
    }
}

// MARK: - Alternate App Icon
public struct AppIconOption: Identifiable {
    public let id: Int
    public let name: String
    public let iconName: String?
    public let previewAsset: String
    
    public static let allIcons: [AppIconOption] = [
        AppIconOption(id: 0, name: "Green", iconName: nil, previewAsset: "ic_launcher_art"),
        AppIconOption(id: 1, name: "Liquid Glass Light", iconName: "IconLiquidLight", previewAsset: "ic_launcher_white_art"),
        AppIconOption(id: 2, name: "Liquid Glass Dark", iconName: "IconLiquidDark", previewAsset: "ic_launcher_glass_art"),
        AppIconOption(id: 3, name: "Red", iconName: "IconRed", previewAsset: "ic_launcher_red_art"),
        AppIconOption(id: 4, name: "Gradient", iconName: "IconGradientWhite", previewAsset: "ic_launcher_white_art"),
        AppIconOption(id: 5, name: "Sunset", iconName: "IconSunset", previewAsset: "ic_launcher_sunset_art"),
        AppIconOption(id: 6, name: "Dark Glass", iconName: "IconDarkGlass", previewAsset: "ic_launcher_glass_art"),
        AppIconOption(id: 7, name: "Pink Note", iconName: "IconPinkNote", previewAsset: "ic_launcher_pink_art"),
        AppIconOption(id: 8, name: "Minimal Green", iconName: "IconMinimalGreen", previewAsset: "ic_launcher_art"),
        AppIconOption(id: 9, name: "Minimal Dark", iconName: "IconMinimalDark", previewAsset: "ic_launcher_glass_art"),
        AppIconOption(id: 10, name: "Minimal Light", iconName: "IconMinimalLight", previewAsset: "ic_launcher_white_art"),
        AppIconOption(id: 11, name: "Gold", iconName: "IconGold", previewAsset: "ic_launcher_gold_art"),
        AppIconOption(id: 12, name: "Rose", iconName: "IconRose", previewAsset: "ic_launcher_rose_art"),
        AppIconOption(id: 13, name: "Purple", iconName: "IconPurple", previewAsset: "ic_launcher_purple_art"),
        AppIconOption(id: 14, name: "Blue", iconName: "IconBlue", previewAsset: "ic_launcher_blue_art")
    ]
}

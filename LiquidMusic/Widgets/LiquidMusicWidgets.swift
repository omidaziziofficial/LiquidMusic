import WidgetKit
import SwiftUI

public struct MusicWidgetEntry: TimelineEntry {
    public let date: Date
    public let title: String
    public let artist: String
    public let album: String
    public let isPlaying: Bool
    public let progress: Double // 0.0 .. 1.0
}

public struct MusicWidgetProvider: TimelineProvider {
    public func placeholder(in context: Context) -> MusicWidgetEntry {
        MusicWidgetEntry(date: Date(), title: "Liquid Sound", artist: "Liquid Music", album: "Glass Era", isPlaying: true, progress: 0.45)
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (MusicWidgetEntry) -> Void) {
        completion(MusicWidgetEntry(date: Date(), title: "Liquid Sound", artist: "Liquid Music", album: "Glass Era", isPlaying: true, progress: 0.45))
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<MusicWidgetEntry>) -> Void) {
        let entry = MusicWidgetEntry(date: Date(), title: "Liquid Sound", artist: "Liquid Music", album: "Glass Era", isPlaying: true, progress: 0.45)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60)))
        completion(timeline)
    }
}

// MARK: - Widget 1: Now Playing Tile (Small)
public struct SmallTileWidgetView: View {
    public let entry: MusicWidgetEntry
    
    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x1C1C1E), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: 0x31D558).gradient)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.white)
                            .font(.title2)
                    )
                    .frame(width: 48, height: 48)
                
                Spacer()
                
                Text(entry.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(entry.artist)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(1)
            }
            .padding(14)
        }
    }
}

// MARK: - Widget 2: Now Playing Glass Card (Medium)
public struct MediumGlassCardWidgetView: View {
    public let entry: MusicWidgetEntry
    
    public var body: some View {
        ZStack {
            Color(hex: 0x1C1C1E)
            
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [Color(hex: 0x31D558), Color(hex: 0x0AB4FF)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(entry.artist)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.65))
                            .lineLimit(1)
                    }
                    
                    // Progress
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.2)).frame(height: 4)
                            Capsule().fill(Color(hex: 0x31D558)).frame(width: geo.size.width * CGFloat(entry.progress), height: 4)
                        }
                    }
                    .frame(height: 4)
                    
                    // Controls
                    HStack(spacing: 20) {
                        Image(systemName: "backward.fill").foregroundColor(.white).font(.body)
                        Image(systemName: entry.isPlaying ? "pause.fill" : "play.fill").foregroundColor(.white).font(.title3)
                        Image(systemName: "forward.fill").foregroundColor(.white).font(.body)
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Widget 3: Turntable Vinyl (Medium)
public struct TurntableVinylWidgetView: View {
    public let entry: MusicWidgetEntry
    
    public var body: some View {
        ZStack {
            Color(hex: 0x121212)
            
            HStack(spacing: 16) {
                // Vinyl Record
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    
                    Circle()
                        .fill(Color(hex: 0x31D558))
                        .frame(width: 44, height: 44)
                        .overlay(Circle().fill(Color.black).frame(width: 12, height: 12))
                }
                .frame(width: 105, height: 105)
                .shadow(color: .black.opacity(0.5), radius: 8)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(entry.artist)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                    
                    Text(entry.album)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: 0x31D558))
                        .lineLimit(1)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Widget Definitions
public struct LiquidMusicWidget: Widget {
    public let kind: String = "LiquidMusicWidget"
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MusicWidgetProvider()) { entry in
            MediumGlassCardWidgetView(entry: entry)
        }
        .configurationDisplayName("Liquid Music")
        .description("Glass player with real-time controls.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

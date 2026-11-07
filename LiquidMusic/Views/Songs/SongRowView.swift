import SwiftUI

public struct SongRowView: View {
    public let song: Song
    public let palette: LiquidPalette
    public let isCurrent: Bool
    public let isPlaying: Bool
    public let onPlay: () -> Void
    public let onMenu: () -> Void
    
    @ObservedObject var store = LibraryStore.shared
    
    public var body: some View {
        Button {
            onPlay()
        } label: {
            HStack(spacing: 12) {
                // Artwork
                ZStack {
                    ArtworkImageView(song: song, size: 48, cornerRadius: 10)
                    
                    if isCurrent {
                        Color.black.opacity(0.35)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        
                        Image(systemName: isPlaying ? "waveform" : "pause.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(palette.accent)
                    }
                }
                
                // Song Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(song.title)
                        .font(.system(size: 16, weight: isCurrent ? .bold : .medium))
                        .foregroundColor(isCurrent ? palette.accent : palette.text)
                        .lineLimit(1)
                    
                    Text("\(song.artist) • \(song.album)")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(palette.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Duration & Menu
                Text(song.formattedDuration)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(palette.tertiary)
                
                Button {
                    onMenu()
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(palette.secondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

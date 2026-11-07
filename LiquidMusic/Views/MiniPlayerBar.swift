import SwiftUI

public struct MiniPlayerBar: View {
    @ObservedObject var player = AudioPlayerService.shared
    @ObservedObject var store = LibraryStore.shared
    
    public let palette: LiquidPalette
    public let onTap: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    
    public var body: some View {
        if let song = player.currentSong {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Artwork with spring scale
                    ArtworkImageView(song: song, size: 44, cornerRadius: 10)
                        .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
                    
                    // Title & Artist
                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(palette.text)
                            .lineLimit(1)
                        
                        Text(song.artist)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(palette.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Controls
                    HStack(spacing: 16) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                player.playPause()
                            }
                        } label: {
                            Image(systemName: player.state.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(palette.text)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            player.next()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(player.state.hasNext ? palette.text : palette.tertiary)
                                .frame(width: 32, height: 32)
                        }
                        .disabled(!player.state.hasNext)
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                
                // Progress Bar at Bottom
                GeometryReader { geo in
                    let progress = player.durationSeconds > 0 ? player.currentPositionSeconds / player.durationSeconds : 0
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(palette.separator)
                            .frame(height: 2)
                        
                        Rectangle()
                            .fill(palette.accent)
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(progress))), height: 2)
                    }
                }
                .frame(height: 2)
            }
            .background {
                if palette.reduceTransparency {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(palette.surface)
                        .shadow(color: Color.black.opacity(palette.isDark ? 0.4 : 0.1), radius: 14, x: 0, y: 6)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.ultraThinMaterial)
                        
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(palette.glassTint)
                        
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(palette.glassRim, lineWidth: 0.6)
                    }
                    .shadow(color: Color.black.opacity(palette.isDark ? 0.5 : 0.12), radius: 18, x: 0, y: 8)
                }
            }
            .offset(x: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if store.settings.swipeCover {
                            dragOffset = gesture.translation.width * 0.5
                        }
                    }
                    .onEnded { gesture in
                        if store.settings.swipeCover {
                            if gesture.translation.width < -60 {
                                player.next()
                            } else if gesture.translation.width > 60 {
                                player.previous()
                            }
                            withAnimation(.spring()) {
                                dragOffset = 0
                            }
                        }
                    }
            )
            .onTapGesture {
                onTap()
            }
            .padding(.horizontal, 12)
        }
    }
}

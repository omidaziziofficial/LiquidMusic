import SwiftUI

public struct NowPlayingView: View {
    @ObservedObject var player = AudioPlayerService.shared
    @ObservedObject var store = LibraryStore.shared
    public let palette: LiquidPalette
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var showLyrics: Bool = false
    @State private var showQueueSheet: Bool = false
    @State private var showEqualizerSheet: Bool = false
    @State private var showSleepSheet: Bool = false
    @State private var showSongMenu: Bool = false
    @State private var isDraggingSlider: Bool = false
    @State private var dragSliderValue: Double = 0
    
    public var body: some View {
        ZStack {
            // Dynamic Artwork Background Blur
            if store.settings.artworkBackground, let song = player.currentSong {
                ArtworkImageView(song: song, size: 600, cornerRadius: 0)
                    .blur(radius: 65)
                    .scaleEffect(1.2)
                    .opacity(palette.isDark ? 0.45 : 0.28)
                    .ignoresSafeArea()
            } else {
                palette.background.ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.compact.down")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(palette.text.opacity(0.75))
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("PLAYING FROM")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(palette.tertiary)
                            .tracking(1.0)
                        
                        Text(player.currentSong?.album ?? "Liquid Music")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(palette.text)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Lyrics Mode Toggle Button
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            showLyrics.toggle()
                        }
                    } label: {
                        Image(systemName: showLyrics ? "quote.bubble.fill" : "quote.bubble")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(showLyrics ? palette.accent : palette.text.opacity(0.75))
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                
                if showLyrics {
                    // Full Screen Synchronized Lyrics
                    if let song = player.currentSong {
                        LyricsView(song: song, palette: palette)
                            .transition(.opacity)
                    }
                } else {
                    // Standard Now Playing Body
                    VStack(spacing: 24) {
                        Spacer()
                        
                        // Large Artwork
                        ArtworkImageView(song: player.currentSong, size: 300, cornerRadius: 24)
                            .shadow(color: Color.black.opacity(palette.isDark ? 0.55 : 0.25), radius: 24, x: 0, y: 12)
                            .scaleEffect(player.state.isPlaying ? 1.0 : 0.88)
                            .animation(.spring(response: 0.45, dampingFraction: 0.65), value: player.state.isPlaying)
                        
                        Spacer()
                        
                        // Song Info + Favorite Button
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(player.currentSong?.title ?? "Not Playing")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(palette.text)
                                    .lineLimit(1)
                                
                                Text(player.currentSong?.artist ?? "")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(palette.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            if let song = player.currentSong {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                        store.toggleFavorite(songId: song.id)
                                    }
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                } label: {
                                    Image(systemName: store.isFavorite(songId: song.id) ? "heart.fill" : "heart")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(store.isFavorite(songId: song.id) ? .red : palette.secondary)
                                        .scaleEffect(store.isFavorite(songId: song.id) ? 1.15 : 1.0)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 28)
                        
                        // Scrubber Slider
                        VStack(spacing: 6) {
                            GeometryReader { geo in
                                let totalWidth = geo.size.width
                                let dur = max(1.0, player.durationSeconds)
                                let current = isDraggingSlider ? dragSliderValue : player.currentPositionSeconds
                                let progress = max(0, min(1.0, current / dur))
                                
                                ZStack(alignment: .leading) {
                                    // Track background
                                    Capsule()
                                        .fill(palette.fill)
                                        .frame(height: 6)
                                    
                                    // Played bar
                                    Capsule()
                                        .fill(palette.accent)
                                        .frame(width: totalWidth * CGFloat(progress), height: 6)
                                    
                                    // Thumb
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 16, height: 16)
                                        .shadow(color: Color.black.opacity(0.2), radius: 3)
                                        .offset(x: max(0, min(totalWidth - 16, (totalWidth * CGFloat(progress)) - 8)))
                                }
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { gesture in
                                            isDraggingSlider = true
                                            let clampedX = max(0, min(totalWidth, gesture.location.x))
                                            let pct = Double(clampedX / totalWidth)
                                            dragSliderValue = pct * dur
                                        }
                                        .onEnded { gesture in
                                            isDraggingSlider = false
                                            let clampedX = max(0, min(totalWidth, gesture.location.x))
                                            let pct = Double(clampedX / totalWidth)
                                            player.seek(to: pct * dur)
                                        }
                                )
                            }
                            .frame(height: 18)
                            
                            // Time Labels
                            HStack {
                                let current = isDraggingSlider ? dragSliderValue : player.currentPositionSeconds
                                Text(formatTime(current))
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(palette.tertiary)
                                
                                Spacer()
                                
                                let remaining = max(0, player.durationSeconds - current)
                                Text("-" + formatTime(remaining))
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(palette.tertiary)
                            }
                        }
                        .padding(.horizontal, 28)
                        
                        // Playback Control Capsule
                        HStack(spacing: 28) {
                            // Shuffle
                            Button {
                                player.toggleShuffle()
                            } label: {
                                Image(systemName: "shuffle")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(player.state.shuffle ? palette.accent : palette.secondary)
                            }
                            
                            // Previous
                            Button {
                                player.previous()
                            } label: {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(palette.text)
                            }
                            
                            // Play / Pause (Large Glass Orb)
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    player.playPause()
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(palette.accent)
                                        .frame(width: 72, height: 72)
                                        .shadow(color: palette.accent.opacity(0.4), radius: 14, x: 0, y: 6)
                                    
                                    Image(systemName: player.state.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 30, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .liquidLens()
                            
                            // Next
                            Button {
                                player.next()
                            } label: {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(player.state.hasNext ? palette.text : palette.tertiary)
                            }
                            .disabled(!player.state.hasNext)
                            
                            // Repeat
                            Button {
                                player.toggleRepeat()
                            } label: {
                                Image(systemName: player.state.repeatMode.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(player.state.repeatMode != .off ? palette.accent : palette.secondary)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                }
                
                // Bottom Tools Bar
                HStack(spacing: 36) {
                    Button {
                        showEqualizerSheet = true
                    } label: {
                        Image(systemName: "slider.vertical.3")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(palette.secondary)
                    }
                    
                    Button {
                        showQueueSheet = true
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(palette.secondary)
                    }
                    
                    Button {
                        showSleepSheet = true
                    } label: {
                        Image(systemName: player.sleepTimerActive ? "moon.fill" : "moon")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(player.sleepTimerActive ? palette.accent : palette.secondary)
                    }
                    
                    Button {
                        showSongMenu = true
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(palette.secondary)
                    }
                }
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial.opacity(0.35))
            }
        }
        .sheet(isPresented: $showQueueSheet) {
            QueueView(palette: palette)
        }
        .sheet(isPresented: $showEqualizerSheet) {
            EqualizerView(palette: palette)
        }
        .sheet(isPresented: $showSleepSheet) {
            SleepTimerSheet(palette: palette)
        }
        .sheet(isPresented: $showSongMenu) {
            if let song = player.currentSong {
                SongActionMenuSheet(song: song, palette: palette)
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Synchronized Lyrics View
public struct LyricsView: View {
    public let song: Song
    public let palette: LiquidPalette
    @ObservedObject var lyricsService = LyricsService.shared
    @ObservedObject var player = AudioPlayerService.shared
    
    @State private var showLyricsEditor: Bool = false
    
    public var body: some View {
        VStack(spacing: 0) {
            if lyricsService.isLoading {
                VStack(spacing: 12) {
                    ProgressView().tint(palette.accent)
                    Text("Looking for lyrics...")
                        .font(.subheadline)
                        .foregroundColor(palette.secondary)
                }
                .frame(maxHeight: .infinity)
            } else if let lyrics = lyricsService.currentLyrics, !lyrics.lines.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(Array(lyrics.lines.enumerated()), id: \.element.id) { index, line in
                                let isCurrent = isLineActive(lineIndex: index, lines: lyrics.lines, currentTimeMs: player.state.position)
                                
                                Button {
                                    player.seek(to: Double(line.timeMs) / 1000.0)
                                } label: {
                                    Text(line.text)
                                        .font(.system(size: isCurrent ? 26 : 20, weight: isCurrent ? .bold : .medium))
                                        .foregroundColor(isCurrent ? palette.accent : palette.secondary)
                                        .scaleEffect(isCurrent ? 1.05 : 1.0, anchor: .leading)
                                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isCurrent)
                                        .multilineTextAlignment(.leading)
                                }
                                .id(line.id)
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 40)
                    }
                    .onChange(of: player.state.position) { pos in
                        if let activeIndex = lyrics.lines.lastIndex(where: { $0.timeMs <= pos }) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                proxy.scrollTo(lyrics.lines[activeIndex].id, anchor: .center)
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 14) {
                    Image(systemName: "quote.bubble")
                        .font(.system(size: 44))
                        .foregroundColor(palette.tertiary)
                    Text("No Lyrics Yet")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(palette.text)
                    Text("Type or paste lyrics, or search online.")
                        .font(.subheadline)
                        .foregroundColor(palette.secondary)
                    
                    HStack(spacing: 12) {
                        Button("Search Online") {
                            Task {
                                _ = await lyricsService.fetchOnlineLyrics(for: song)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(palette.accent)
                        
                        Button("Add Lyrics") {
                            showLyricsEditor = true
                        }
                        .buttonStyle(.bordered)
                        .tint(palette.text)
                    }
                    .padding(.top, 10)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .task(id: song.id) {
            _ = await lyricsService.loadLyrics(for: song)
        }
        .sheet(isPresented: $showLyricsEditor) {
            LyricsEditorSheet(song: song, palette: palette)
        }
    }
    
    private func isLineActive(lineIndex: Int, lines: [LyricLine], currentTimeMs: Int64) -> Bool {
        let currentLine = lines[lineIndex]
        guard currentTimeMs >= currentLine.timeMs else { return false }
        if lineIndex < lines.count - 1 {
            return currentTimeMs < lines[lineIndex + 1].timeMs
        }
        return true
    }
}

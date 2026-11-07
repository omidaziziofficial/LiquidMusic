import SwiftUI

public struct MainContainerView: View {
    @ObservedObject var store = LibraryStore.shared
    @ObservedObject var player = AudioPlayerService.shared
    @ObservedObject var voiceService = VoiceAssistantService.shared
    @Environment(\.colorScheme) private var systemColorScheme
    
    @State private var selectedTab: Int = 0
    @State private var showNowPlayingSheet: Bool = false
    
    public var isDark: Bool {
        switch store.settings.themeMode {
        case .system: return systemColorScheme == .dark
        case .light: return false
        case .dark: return true
        }
    }
    
    public var palette: LiquidPalette {
        LiquidTheme.palette(
            for: isDark,
            accentIndex: store.settings.accent,
            reduceTransparency: store.settings.reduceTransparency
        )
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content Tabs
            TabView(selection: $selectedTab) {
                SongsView(palette: palette)
                    .tag(0)
                
                LibraryHomeView(palette: palette)
                    .tag(1)
                
                PlaylistsView(palette: palette)
                    .tag(2)
                
                SearchView(palette: palette)
                    .tag(3)
                
                SettingsView(palette: palette)
                    .tag(4)
            }
            .ignoresSafeArea()
            
            // Bottom Floating Stack: MiniPlayer + GlassTabBar
            VStack(spacing: 8) {
                // Mini Player (Visible when a song is loaded)
                if player.currentSong != nil {
                    MiniPlayerBar(palette: palette) {
                        showNowPlayingSheet = true
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Floating Glass Tab Bar
                GlassTabBar(selectedTab: $selectedTab, palette: palette)
            }
        }
        .preferredColorScheme(isDark ? .dark : .light)
        .fullScreenCover(isPresented: $showNowPlayingSheet) {
            NowPlayingView(palette: palette)
        }
        .onChange(of: voiceService.activeNavigationRoute) { route in
            guard let route = route else { return }
            switch route {
            case "songs": selectedTab = 0
            case "library", "artist", "album", "favorites": selectedTab = 1
            case "playlists": selectedTab = 2
            case "search": selectedTab = 3
            case "settings": selectedTab = 4
            default: break
            }
            voiceService.activeNavigationRoute = nil
        }
    }
}

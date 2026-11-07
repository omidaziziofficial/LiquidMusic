import SwiftUI

@main
struct LiquidMusicApp: App {
    @StateObject private var libraryStore = LibraryStore.shared
    @StateObject private var player = AudioPlayerService.shared
    @StateObject private var voiceService = VoiceAssistantService.shared
    
    var body: some Scene {
        WindowGroup {
            MainContainerView()
                .onAppear {
                    voiceService.startListeningIfEnabled()
                }
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        if url.pathExtension.lowercased() == "zip" {
            // Import Playlist
            Task {
                _ = try? await PlaylistArchiveService.shared.importPlaylist(from: url)
            }
        } else {
            // Audio file opened from Files or AirDrop
            let ext = url.pathExtension.lowercased()
            let audioExtensions = ["mp3", "m4a", "wav", "flac", "aac", "ogg"]
            if audioExtensions.contains(ext) {
                let musicDir = libraryStore.musicDirectoryURL
                let destination = musicDir.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.removeItem(at: destination)
                try? FileManager.default.copyItem(at: url, to: destination)
                
                Task {
                    await libraryStore.rescanLibrary()
                    if let song = libraryStore.songs.first(where: { $0.title == destination.deletingPathExtension().lastPathComponent }) {
                        player.playSongs([song])
                    }
                }
            }
        }
    }
}

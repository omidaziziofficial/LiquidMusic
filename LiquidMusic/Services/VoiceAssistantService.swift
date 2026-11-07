import Foundation
import Speech
import AVFoundation
import SwiftUI
import Combine

@MainActor
public final class VoiceAssistantService: ObservableObject {
    public static let shared = VoiceAssistantService()
    
    @Published public var isListening: Bool = false
    @Published public var lastCommandRecognized: String?
    @Published public var activeNavigationRoute: String?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private let libraryStore = LibraryStore.shared
    private let player = AudioPlayerService.shared
    
    private init() {}
    
    public func startListeningIfEnabled() {
        guard libraryStore.settings.voiceControl else {
            stopListening()
            return
        }
        
        requestAuthorization { [weak self] authorized in
            guard authorized else { return }
            Task { @MainActor [weak self] in
                self?.startRecording()
            }
        }
    }
    
    public func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }
    
    private func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
    
    private func startRecording() {
        stopListening()
        
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        if speechRecognizer?.supportsOnDeviceRecognition == true {
            recognitionRequest.requiresOnDeviceRecognition = true
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                let text = result.bestTranscription.formattedString.lowercased()
                Task { @MainActor in
                    self.processSpokenText(text)
                }
            }
            if error != nil {
                // Restart listening loop if voice control is still active
                if self.libraryStore.settings.voiceControl {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.startRecording()
                    }
                }
            }
        }
        
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
        } catch {
            print("Audio engine error: \(error)")
        }
    }
    
    private func processSpokenText(_ text: String) {
        // Must contain "jarvis" or "hey jarvis"
        guard text.contains("jarvis") else { return }
        
        // Extract command following jarvis
        let commands: [(phrase: String, action: () -> Void)] = [
            ("play music", { self.player.resume() }),
            ("pause music", { self.player.pause() }),
            ("stop music", { self.player.pause() }),
            ("next music", { self.player.next() }),
            ("previous music", { self.player.previous() }),
            ("repeat music", { self.player.seek(to: 0) }),
            ("mute music", { /* Toggle Mute */ }),
            ("open songs", { self.activeNavigationRoute = "songs" }),
            ("open artist", { self.activeNavigationRoute = "artist" }),
            ("open album", { self.activeNavigationRoute = "album" }),
            ("open search", { self.activeNavigationRoute = "search" }),
            ("open favorites", { self.activeNavigationRoute = "favorites" }),
            ("add favorites", {
                if let song = self.player.currentSong {
                    self.libraryStore.toggleFavorite(songId: song.id)
                }
            }),
            ("remove favorites", {
                if let song = self.player.currentSong {
                    self.libraryStore.toggleFavorite(songId: song.id)
                }
            }),
            ("open playlist", { self.activeNavigationRoute = "playlists" }),
            ("open settings", { self.activeNavigationRoute = "settings" }),
            ("turn on dark mode", {
                self.libraryStore.updateSettings { $0.themeMode = .dark }
            }),
            ("turn on light mode", {
                self.libraryStore.updateSettings { $0.themeMode = .light }
            })
        ]
        
        for cmd in commands {
            if text.contains(cmd.phrase) {
                lastCommandRecognized = cmd.phrase
                cmd.action()
                // Provide haptic feedback
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                break
            }
        }
    }
}

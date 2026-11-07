import Foundation
import AVFoundation
import MediaPlayer
import Combine
import SwiftUI

@MainActor
public final class AudioPlayerService: ObservableObject {
    public static let shared = AudioPlayerService()
    
    @Published public var state: PlayerState = PlayerState()
    @Published public var currentSong: Song?
    @Published public var currentPositionSeconds: Double = 0
    @Published public var durationSeconds: Double = 0
    @Published public var sleepTimerRemainingSeconds: Int = 0
    @Published public var sleepTimerActive: Bool = false
    
    private var primaryPlayer: AVPlayer?
    private var secondaryPlayer: AVPlayer?
    private var isUsingPrimary: Bool = true
    
    private var timeObserverToken: Any?
    private var sleepTimer: Timer?
    private var crossfadeTimer: Timer?
    
    private let libraryStore = LibraryStore.shared
    
    private init() {
        configureAudioSession()
        configureRemoteCommands()
    }
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    // MARK: - Playback Controls
    public func playSongs(_ songs: [Song], startIndex: Int = 0, shuffle: Bool = false) {
        guard !songs.isEmpty else { return }
        var queue = songs.map { $0.id }
        var index = startIndex
        
        if shuffle {
            let first = queue.remove(at: startIndex)
            queue.shuffle()
            queue.insert(first, at: 0)
            index = 0
        }
        
        state.queue = queue
        state.index = index
        state.shuffle = shuffle
        updateNavigationState()
        
        loadAndPlay(songId: queue[index], isCrossfade: false)
    }
    
    public func playPause() {
        if state.isPlaying {
            pause()
        } else {
            resume()
        }
    }
    
    public func resume() {
        currentPlayer?.play()
        state.isPlaying = true
        updateNowPlayingInfo()
    }
    
    public func pause() {
        currentPlayer?.pause()
        state.isPlaying = false
        updateNowPlayingInfo()
    }
    
    public func next() {
        guard state.hasNext else { return }
        let nextIndex = state.index + 1
        state.index = nextIndex
        updateNavigationState()
        
        let shouldCrossfade = libraryStore.settings.crossfadeManual && libraryStore.settings.crossfade
        loadAndPlay(songId: state.queue[nextIndex], isCrossfade: shouldCrossfade)
    }
    
    public func previous() {
        // If restart on previous enabled or position > 3 seconds, restart current track
        if libraryStore.settings.restartOnPrevious && currentPositionSeconds > 3.0 {
            seek(to: 0)
            return
        }
        
        guard state.hasPrevious else {
            seek(to: 0)
            return
        }
        
        let prevIndex = state.index - 1
        state.index = prevIndex
        updateNavigationState()
        
        let shouldCrossfade = libraryStore.settings.crossfadeManual && libraryStore.settings.crossfade
        loadAndPlay(songId: state.queue[prevIndex], isCrossfade: shouldCrossfade)
    }
    
    public func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        currentPlayer?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        currentPositionSeconds = seconds
        state.position = Int64(seconds * 1000)
        updateNowPlayingInfo()
    }
    
    public func toggleShuffle() {
        state.shuffle.toggle()
        guard let current = currentSong else { return }
        if state.shuffle {
            var remaining = state.queue.filter { $0 != current.id }
            remaining.shuffle()
            state.queue = [current.id] + remaining
            state.index = 0
        } else {
            // Restore original library order
            let currentId = current.id
            state.queue = libraryStore.songs.map { $0.id }
            if let idx = state.queue.firstIndex(of: currentId) {
                state.index = idx
            }
        }
        updateNavigationState()
    }
    
    public func toggleRepeat() {
        switch state.repeatMode {
        case .off: state.repeatMode = .all
        case .all: state.repeatMode = .one
        case .one: state.repeatMode = .off
        }
    }
    
    public func addToQueueNext(song: Song) {
        if state.queue.isEmpty {
            playSongs([song])
        } else {
            state.queue.insert(song.id, at: state.index + 1)
            updateNavigationState()
        }
    }
    
    public func addToQueueLast(song: Song) {
        if state.queue.isEmpty {
            playSongs([song])
        } else {
            state.queue.append(song.id)
            updateNavigationState()
        }
    }
    
    public func removeQueueItem(at index: Int) {
        guard index >= 0 && index < state.queue.count else { return }
        state.queue.remove(at: index)
        if index < state.index {
            state.index -= 1
        }
        updateNavigationState()
    }
    
    public func reorderQueue(from source: IndexSet, to destination: Int) {
        state.queue.move(fromOffsets: source, toOffset: destination)
        if let current = currentSong, let newIdx = state.queue.firstIndex(of: current.id) {
            state.index = newIdx
        }
        updateNavigationState()
    }
    
    public func clearQueue() {
        if let current = currentSong {
            state.queue = [current.id]
            state.index = 0
        } else {
            state.queue = []
            state.index = -1
        }
        updateNavigationState()
    }
    
    // MARK: - Core Audio Loading & Crossfade
    private var currentPlayer: AVPlayer? {
        isUsingPrimary ? primaryPlayer : secondaryPlayer
    }
    
    private func loadAndPlay(songId: Int64, isCrossfade: Bool) {
        guard let song = libraryStore.songsMap[songId] else { return }
        currentSong = song
        state.currentId = song.id
        
        libraryStore.recordPlayback(songId: song.id)
        
        guard let url = URL(string: song.uri) ?? URL(fileURLWithPath: song.path) as URL? else { return }
        let playerItem = AVPlayerItem(url: url)
        
        let crossfadeDuration = Double(libraryStore.settings.crossfadeSec)
        
        if isCrossfade && libraryStore.settings.crossfade && currentPlayer != nil {
            // Swap players for crossfade
            let oldPlayer = currentPlayer
            isUsingPrimary.toggle()
            let newPlayer = AVPlayer(playerItem: playerItem)
            if isUsingPrimary {
                primaryPlayer = newPlayer
            } else {
                secondaryPlayer = newPlayer
            }
            
            newPlayer.volume = 0.0
            newPlayer.play()
            
            // Crossfade transition over crossfadeDuration
            let steps = 30
            let interval = crossfadeDuration / Double(steps)
            var currentStep = 0
            
            crossfadeTimer?.invalidate()
            crossfadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
                Task { @MainActor [weak self] in
                    guard let self = self else { timer.invalidate(); return }
                    currentStep += 1
                    let progress = Float(currentStep) / Float(steps)
                    newPlayer.volume = progress
                    oldPlayer?.volume = 1.0 - progress
                    
                    if currentStep >= steps {
                        timer.invalidate()
                        oldPlayer?.pause()
                        oldPlayer?.replaceCurrentItem(with: nil)
                    }
                }
            }
            
            setupPlayerObservers(for: newPlayer)
        } else {
            // Standard instant load
            crossfadeTimer?.invalidate()
            let player = AVPlayer(playerItem: playerItem)
            player.volume = 1.0
            primaryPlayer?.pause()
            secondaryPlayer?.pause()
            primaryPlayer = player
            secondaryPlayer = nil
            isUsingPrimary = true
            player.play()
            
            setupPlayerObservers(for: player)
        }
        
        state.isPlaying = true
        updateNowPlayingInfo()
    }
    
    private func setupPlayerObservers(for player: AVPlayer) {
        if let token = timeObserverToken {
            primaryPlayer?.removeTimeObserver(token)
            secondaryPlayer?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let currentSec = CMTimeGetSeconds(time)
                if !currentSec.isNaN && !currentSec.isInfinite {
                    self.currentPositionSeconds = currentSec
                    self.state.position = Int64(currentSec * 1000)
                    
                    if let item = player.currentItem {
                        let dur = CMTimeGetSeconds(item.duration)
                        if !dur.isNaN && !dur.isInfinite {
                            self.durationSeconds = dur
                            self.state.duration = Int64(dur * 1000)
                            
                            // Check automatic crossfade near end of track
                            if self.libraryStore.settings.crossfade && self.state.hasNext {
                                let crossfadeSec = Double(self.libraryStore.settings.crossfadeSec)
                                if (dur - currentSec) <= crossfadeSec && (dur - currentSec) > (crossfadeSec - 0.3) {
                                    self.next()
                                }
                            }
                        }
                    }
                }
            }
        }
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.state.repeatMode == .one {
                    self.seek(to: 0)
                    self.resume()
                } else if self.state.hasNext {
                    self.next()
                } else if self.state.repeatMode == .all && !self.state.queue.isEmpty {
                    self.state.index = 0
                    self.updateNavigationState()
                    self.loadAndPlay(songId: self.state.queue[0], isCrossfade: false)
                } else {
                    self.state.isPlaying = false
                }
            }
        }
    }
    
    private func updateNavigationState() {
        state.hasNext = state.index >= 0 && state.index < state.queue.count - 1
        state.hasPrevious = state.index > 0
    }
    
    // MARK: - Sleep Timer
    public func startSleepTimer(mode: SleepTimerMode) {
        sleepTimer?.invalidate()
        sleepTimer = nil
        
        switch mode {
        case .off:
            sleepTimerActive = false
            sleepTimerRemainingSeconds = 0
        case .endOfTrack:
            sleepTimerActive = true
            let remaining = max(0, Int(durationSeconds - currentPositionSeconds))
            sleepTimerRemainingSeconds = remaining
            scheduleSleepCountdown(seconds: remaining)
        case .minutes(let mins):
            sleepTimerActive = true
            let totalSecs = mins * 60
            sleepTimerRemainingSeconds = totalSecs
            scheduleSleepCountdown(seconds: totalSecs)
        }
    }
    
    public func extendSleepTimer(minutes: Int = 15) {
        guard sleepTimerActive else {
            startSleepTimer(mode: .minutes(minutes))
            return
        }
        sleepTimerRemainingSeconds += (minutes * 60)
    }
    
    public func cancelSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        sleepTimerActive = false
        sleepTimerRemainingSeconds = 0
    }
    
    private func scheduleSleepCountdown(seconds: Int) {
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self = self else { timer.invalidate(); return }
                if self.sleepTimerRemainingSeconds > 0 {
                    self.sleepTimerRemainingSeconds -= 1
                    
                    // Fade out on sleep if setting enabled in last 10 seconds
                    if self.libraryStore.settings.fadeOnSleep && self.sleepTimerRemainingSeconds <= 10 {
                        let volume = Float(self.sleepTimerRemainingSeconds) / 10.0
                        self.currentPlayer?.volume = max(0, volume)
                    }
                } else {
                    timer.invalidate()
                    self.sleepTimerActive = false
                    self.pause()
                    self.currentPlayer?.volume = 1.0
                }
            }
        }
    }
    
    // MARK: - Lock Screen & Remote Controls
    private func configureRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.resume() }
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.pause() }
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.playPause() }
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.next() }
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.previous() }
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor [weak self] in self?.seek(to: positionEvent.positionTime) }
            return .success
        }
    }
    
    public func updateNowPlayingInfo() {
        guard let song = currentSong else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artist,
            MPMediaItemPropertyAlbumTitle: song.album,
            MPMediaItemPropertyPlaybackDuration: durationSeconds,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentPositionSeconds,
            MPNowPlayingInfoPropertyPlaybackRate: state.isPlaying ? 1.0 : 0.0
        ]
        
        if let coverPath = song.coverPath, let image = UIImage(contentsOfFile: coverPath) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

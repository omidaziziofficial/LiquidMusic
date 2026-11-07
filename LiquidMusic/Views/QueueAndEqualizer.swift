import SwiftUI

public struct QueueView: View {
    @ObservedObject var player = AudioPlayerService.shared
    @ObservedObject var store = LibraryStore.shared
    public let palette: LiquidPalette
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        NavigationStack {
            ZStack {
                palette.background.ignoresSafeArea()
                
                List {
                    // Now Playing Song
                    if let current = player.currentSong {
                        Section(header: Text("Now Playing")) {
                            HStack(spacing: 12) {
                                ArtworkImageView(song: current, size: 44, cornerRadius: 8)
                                VStack(alignment: .leading) {
                                    Text(current.title)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(palette.accent)
                                    Text(current.artist)
                                        .font(.system(size: 13))
                                        .foregroundColor(palette.secondary)
                                }
                                Spacer()
                                Image(systemName: "waveform")
                                    .foregroundColor(palette.accent)
                            }
                        }
                    }
                    
                    // Playing Next
                    Section(header: HStack {
                        Text("Playing Next")
                        Spacer()
                        Button("Clear") {
                            player.clearQueue()
                        }
                        .foregroundColor(palette.accent)
                    }) {
                        let upcomingIndices = Array((player.state.index + 1)..<player.state.queue.count)
                        if upcomingIndices.isEmpty {
                            Text("Nothing else is queued up")
                                .foregroundColor(palette.secondary)
                        } else {
                            ForEach(upcomingIndices, id: \.self) { idx in
                                let songId = player.state.queue[idx]
                                if let song = store.songsMap[songId] {
                                    HStack(spacing: 12) {
                                        ArtworkImageView(song: song, size: 40, cornerRadius: 8)
                                        VStack(alignment: .leading) {
                                            Text(song.title)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(palette.text)
                                            Text(song.artist)
                                                .font(.system(size: 13))
                                                .foregroundColor(palette.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "line.3.horizontal")
                                            .foregroundColor(palette.tertiary)
                                    }
                                }
                            }
                            .onDelete { indexSet in
                                for offset in indexSet {
                                    let actualIdx = upcomingIndices[offset]
                                    player.removeQueueItem(at: actualIdx)
                                }
                            }
                            .onMove { source, destination in
                                player.reorderQueue(from: source, to: destination)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Playing Next")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton().foregroundColor(palette.accent)
                }
            }
        }
    }
}

// MARK: - Equalizer View
public struct EqualizerView: View {
    public let palette: LiquidPalette
    @Environment(\.dismiss) private var dismiss
    
    @State private var eqEnabled: Bool = true
    @State private var selectedPreset: String = "Flat"
    @State private var bands: [Double] = [0, 0, 0, 0, 0] // 60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz
    
    private let frequencies = ["60 Hz", "230 Hz", "910 Hz", "3.6 kHz", "14 kHz"]
    private let presets: [String: [Double]] = [
        "Flat": [0, 0, 0, 0, 0],
        "Bass Boost": [5, 4, 1, 0, 0],
        "Acoustic": [3, 2, 0, 2, 3],
        "Electronic": [4, 2, -1, 2, 4],
        "Rock": [4, 2, -1, 1, 4],
        "Vocal": [-2, 1, 4, 2, -1],
        "Pop": [1, 2, 3, 2, 1]
    ]
    
    public var body: some View {
        NavigationStack {
            ZStack {
                palette.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Toggle("Equalizer Enabled", isOn: $eqEnabled)
                            .padding()
                            .background(palette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        
                        // Presets Picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(presets.keys.sorted()), id: \.self) { presetName in
                                    let isSelected = selectedPreset == presetName
                                    Button {
                                        selectedPreset = presetName
                                        if let vals = presets[presetName] {
                                            bands = vals
                                        }
                                    } label: {
                                        Text(presetName)
                                            .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(isSelected ? palette.accent : palette.surface)
                                            .foregroundColor(isSelected ? .white : palette.text)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Vertical Band Sliders
                        HStack(spacing: 18) {
                            ForEach(0..<bands.count, id: \.self) { idx in
                                VStack(spacing: 12) {
                                    Text("\(Int(bands[idx])) dB")
                                        .font(.caption2)
                                        .foregroundColor(palette.secondary)
                                    
                                    // Vertical Slider
                                    Slider(value: $bands[idx], in: -10...10, step: 1)
                                        .rotationEffect(.degrees(-90))
                                        .frame(width: 140, height: 40)
                                        .tint(palette.accent)
                                        .disabled(!eqEnabled)
                                    
                                    Text(frequencies[idx])
                                        .font(.caption)
                                        .foregroundColor(palette.text)
                                }
                            }
                        }
                        .padding(.vertical, 30)
                        .frame(maxWidth: .infinity)
                        .background(palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Equalizer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

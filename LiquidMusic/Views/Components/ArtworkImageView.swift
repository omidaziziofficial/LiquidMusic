import Foundation
import SwiftUI
import MediaPlayer
import AVFoundation

public struct ArtworkImageView: View {
    public let song: Song?
    public let size: CGFloat
    public let cornerRadius: CGFloat
    
    @State private var loadedImage: UIImage?
    
    public init(song: Song?, size: CGFloat = 48, cornerRadius: CGFloat = 10) {
        self.song = song
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                defaultPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .task(id: song?.id) {
            await loadArtwork()
        }
    }
    
    private var defaultPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x31D558).opacity(0.85), Color(hex: 0x0AB4FF).opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "music.note")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundColor(.white)
        }
    }
    
    private func loadArtwork() async {
        guard let song = song else {
            loadedImage = nil
            return
        }
        
        // 1. Check custom override cover path
        if let path = song.coverPath, FileManager.default.fileExists(atPath: path),
           let img = UIImage(contentsOfFile: path) {
            loadedImage = img
            return
        }
        
        // 2. Check embedded file metadata
        if let url = URL(string: song.uri) ?? URL(fileURLWithPath: song.path) as URL? {
            let asset = AVURLAsset(url: url)
            for item in asset.commonMetadata {
                if item.commonKey?.rawValue == AVMetadataKey.commonKeyArtwork.rawValue,
                   let data = item.dataValue, let img = UIImage(data: data) {
                    loadedImage = img
                    return
                }
            }
        }
        
        loadedImage = nil
    }
}

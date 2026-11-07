import SwiftUI

public struct GlassTabBar: View {
    @Binding public var selectedTab: Int
    public let palette: LiquidPalette
    
    private let tabs: [(icon: String, title: String)] = [
        ("music.note", "Songs"),
        ("square.grid.2x2.fill", "Library"),
        ("music.note.list", "Playlists"),
        ("magnifyingglass", "Search"),
        ("gearshape.fill", "Settings")
    ]
    
    public var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { idx in
                let tab = tabs[idx]
                let isSelected = selectedTab == idx
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        selectedTab = idx
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: isSelected ? 20 : 18, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? palette.accent : palette.secondary)
                            .scaleEffect(isSelected ? 1.08 : 1.0)
                        
                        Text(tab.title)
                            .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? palette.accent : palette.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            if palette.reduceTransparency {
                Capsule(style: .continuous)
                    .fill(palette.surface)
                    .shadow(color: Color.black.opacity(palette.isDark ? 0.35 : 0.08), radius: 14, x: 0, y: 6)
            } else {
                ZStack {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    Capsule(style: .continuous)
                        .fill(palette.glassTint)
                    
                    Capsule(style: .continuous)
                        .strokeBorder(palette.glassRim, lineWidth: 0.6)
                }
                .shadow(color: Color.black.opacity(palette.isDark ? 0.45 : 0.12), radius: 18, x: 0, y: 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}

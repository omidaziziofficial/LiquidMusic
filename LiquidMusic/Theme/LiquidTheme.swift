import Foundation
import SwiftUI

public struct LiquidPalette {
    public let isDark: Bool
    public let accent: Color
    public let background: Color
    public let surface: Color
    public let elevated: Color
    public let text: Color
    public let secondary: Color
    public let tertiary: Color
    public let separator: Color
    public let fill: Color
    public let glassTint: Color
    public let glassRim: Color
    public let reduceTransparency: Bool
}

public enum LiquidTheme {
    public static let accentColors: [Color] = [
        Color(hex: 0x31D558), // 0: Emerald Green (Default)
        Color(hex: 0x0AB4FF), // 1: Azure Blue
        Color(hex: 0x5E5CE6), // 2: Indigo
        Color(hex: 0xBF5AF2), // 3: Purple
        Color(hex: 0xFF2D5F), // 4: Hot Pink
        Color(hex: 0xFF3B3A), // 5: Crimson Red
        Color(hex: 0xFF950A), // 6: Sunset Orange
        Color(hex: 0xFFCC0A), // 7: Amber Gold
        Color(hex: 0x67D4CF), // 8: Mint Teal
        Color(hex: 0x40C8E0), // 9: Sky Blue
        Color(hex: 0xAC8E68), // 10: Rose Gold
        Color(hex: 0x8E8E93)  // 11: Silver Slate
    ]
    
    public static func accent(for index: Int) -> Color {
        let safeIndex = max(0, min(accentColors.count - 1, index))
        return accentColors[safeIndex]
    }
    
    public static func palette(for isDark: Bool, accentIndex: Int, reduceTransparency: Bool) -> LiquidPalette {
        let accent = self.accent(for: accentIndex)
        if isDark {
            return LiquidPalette(
                isDark: true,
                accent: accent,
                background: Color.black,
                surface: Color(hex: 0x1C1C1E),
                elevated: Color(hex: 0x2C2C2E),
                text: Color.white,
                secondary: Color.white.opacity(0.60),
                tertiary: Color.white.opacity(0.30),
                separator: Color(hex: 0x545458, alpha: 0.35),
                fill: Color(hex: 0x767680, alpha: 0.22),
                glassTint: reduceTransparency ? Color(hex: 0x1C1C1E) : Color(hex: 0x1C1C1E, alpha: 0.45),
                glassRim: Color.white.opacity(0.20),
                reduceTransparency: reduceTransparency
            )
        } else {
            return LiquidPalette(
                isDark: false,
                accent: accent,
                background: Color(hex: 0xF2F2F7),
                surface: Color.white,
                elevated: Color.white,
                text: Color.black,
                secondary: Color.black.opacity(0.60),
                tertiary: Color.black.opacity(0.30),
                separator: Color(hex: 0x3C3C43, alpha: 0.18),
                fill: Color(hex: 0x767680, alpha: 0.12),
                glassTint: reduceTransparency ? Color.white : Color.white.opacity(0.65),
                glassRim: Color.white.opacity(0.80),
                reduceTransparency: reduceTransparency
            )
        }
    }
}

// MARK: - Color Hex Initializer
extension Color {
    public init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255.0,
            green: Double((hex >> 8) & 0xff) / 255.0,
            blue: Double(hex & 0xff) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - Liquid Glass Modifiers
public struct LiquidGlassModifier: ViewModifier {
    public let cornerRadius: CGFloat
    public let palette: LiquidPalette
    
    public func body(content: Content) -> some View {
        content
            .background {
                if palette.reduceTransparency {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(palette.surface)
                        .shadow(color: Color.black.opacity(palette.isDark ? 0.35 : 0.08), radius: 12, x: 0, y: 6)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                        
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(palette.glassTint)
                        
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(palette.glassRim, lineWidth: 0.6)
                    }
                    .shadow(color: Color.black.opacity(palette.isDark ? 0.45 : 0.08), radius: 16, x: 0, y: 8)
                }
            }
    }
}

public struct LiquidLensSpringModifier: ViewModifier {
    @State private var isPressed: Bool = false
    public let scaleAmount: CGFloat
    
    public init(scaleAmount: CGFloat = 0.96) {
        self.scaleAmount = scaleAmount
    }
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scaleAmount : 1.0)
            .animation(.spring(response: 0.32, dampingFraction: 0.7), value: isPressed)
            ._onButtonGesture { pressing in
                self.isPressed = pressing
            } perform: {}
    }
}

extension View {
    public func liquidGlass(cornerRadius: CGFloat = 20, palette: LiquidPalette) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius, palette: palette))
    }
    
    public func liquidLens() -> some View {
        self.modifier(LiquidLensSpringModifier())
    }
}

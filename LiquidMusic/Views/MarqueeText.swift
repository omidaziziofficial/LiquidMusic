import SwiftUI

public struct MarqueeText: View {
    public let text: String
    public let font: Font
    public let color: Color
    
    @State private var animate: Bool = false
    
    public init(text: String, font: Font = .body, color: Color = .primary) {
        self.text = text
        self.font = font
        self.color = color
    }
    
    public var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
            .lineLimit(1)
            .truncationMode(.tail)
    }
}

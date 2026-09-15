import SwiftUI

public struct HydrationStatusLabel: View {
    private let text: String
    private let accent: SemanticColor
    private let typography: HydrationTypography

    public init(text: String, accent: SemanticColor, typography: HydrationTypography) {
        self.text = text
        self.accent = accent
        self.typography = typography
    }

    public var body: some View {
        Text(text)
            .font(typography.status)
            .foregroundStyle(HydrationAccent.color(accent))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
    }
}

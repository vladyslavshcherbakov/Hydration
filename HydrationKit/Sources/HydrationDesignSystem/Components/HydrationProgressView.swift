import SwiftUI

public struct HydrationProgressView: View {

    // MARK: - Style
    public enum Style: Equatable, Sendable {
        case ring(diameter: CGFloat)
        case bar
    }

    private let fraction: Double
    private let accent: SemanticColor
    private let style: Style

    // MARK: - Public
    public init(fraction: Double, accent: SemanticColor, style: Style) {
        self.fraction = fraction
        self.accent = accent
        self.style = style
    }

    @ViewBuilder
    public var body: some View {
        switch style {
        case .ring(let diameter): ring(diameter: diameter)
        case .bar: bar
        }
    }

    // MARK: - Private
    private var filledFraction: Double {
        min(max(fraction, 0), 1)
    }

    private var color: Color {
        HydrationAccent.color(accent)
    }

    private func ring(diameter: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(HydrationMetrics.trackOpacity), lineWidth: HydrationMetrics.ringWidth)
            Circle()
                .trim(from: 0, to: filledFraction)
                .stroke(color, style: StrokeStyle(lineWidth: HydrationMetrics.ringWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: diameter, height: diameter)
        .animation(.easeInOut, value: filledFraction)
    }

    private var bar: some View {
        ProgressView(value: filledFraction).tint(color)
    }
}

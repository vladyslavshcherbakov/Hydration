import SwiftUI

public struct HydrationActionButton: View {

    // MARK: - Prominence
    public enum Prominence: Equatable, Sendable {
        case filled
        case bordered
    }

    private let title: String
    private let accent: SemanticColor
    private let typography: HydrationTypography
    private let prominence: Prominence
    private let isEnabled: Bool
    private let action: () -> Void

    // MARK: - Public
    public init(
        title: String,
        accent: SemanticColor,
        typography: HydrationTypography,
        prominence: Prominence,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.accent = accent
        self.typography = typography
        self.prominence = prominence
        self.isEnabled = isEnabled
        self.action = action
    }

    @ViewBuilder
    public var body: some View {
        switch prominence {
        case .filled: label.buttonStyle(.borderedProminent).tint(color).disabled(!isEnabled)
        case .bordered: label.buttonStyle(.bordered).tint(color).disabled(!isEnabled)
        }
    }

    // MARK: - Private
    private var color: Color {
        HydrationAccent.color(accent)
    }

    private var label: some View {
        Button(title, action: action)
            .font(typography.action)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}

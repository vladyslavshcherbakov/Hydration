import SwiftUI

public struct HydrationTotalLabel: View {
    public enum Layout: Equatable, Sendable {
        case stacked
        case inline
    }

    private let total: String
    private let goal: String
    private let typography: HydrationTypography
    private let layout: Layout
    private let totalIdentifier: String?

    public init(
        total: String,
        goal: String,
        typography: HydrationTypography,
        layout: Layout,
        totalIdentifier: String? = nil
    ) {
        self.total = total
        self.goal = goal
        self.typography = typography
        self.layout = layout
        self.totalIdentifier = totalIdentifier
    }

    @ViewBuilder
    public var body: some View {
        switch layout {
        case .stacked: stacked
        case .inline: inline
        }
    }

    private var stacked: some View {
        VStack(spacing: 4) {
            identifiedTotal
            goalText
        }
    }

    private var inline: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            identifiedTotal
            goalText
        }
    }

    @ViewBuilder
    private var identifiedTotal: some View {
        if let totalIdentifier {
            totalText.accessibilityIdentifier(totalIdentifier)
        } else {
            totalText
        }
    }

    private var totalText: some View {
        Text(total)
            .font(typography.value)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }

    private var goalText: some View {
        Text(goal)
            .font(typography.goal)
            .foregroundStyle(.secondary)
    }
}

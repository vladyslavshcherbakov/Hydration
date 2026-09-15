import SwiftUI

public struct HydrationTypography: Sendable {
    public static let phone = HydrationTypography(
        valueSize: 44,
        goalStyle: .subheadline,
        statusStyle: .headline,
        captionStyle: .footnote
    )

    public static let watch = HydrationTypography(
        valueSize: 30,
        goalStyle: .footnote,
        statusStyle: .footnote,
        captionStyle: .caption2
    )

    public static let widget = HydrationTypography(
        valueSize: 22,
        goalStyle: .caption2,
        statusStyle: .caption2,
        captionStyle: .caption2
    )

    private let valueSize: CGFloat
    private let goalStyle: Font.TextStyle
    private let statusStyle: Font.TextStyle
    private let captionStyle: Font.TextStyle

    private init(valueSize: CGFloat, goalStyle: Font.TextStyle, statusStyle: Font.TextStyle, captionStyle: Font.TextStyle) {
        self.valueSize = valueSize
        self.goalStyle = goalStyle
        self.statusStyle = statusStyle
        self.captionStyle = captionStyle
    }

    public var value: Font {
        .system(size: valueSize, weight: .semibold, design: .rounded)
    }

    public var goal: Font {
        .system(goalStyle, design: .rounded)
    }

    public var status: Font {
        .system(statusStyle, design: .rounded).weight(.semibold)
    }

    public var caption: Font {
        .system(captionStyle, design: .rounded)
    }

    public var action: Font {
        .system(.body, design: .rounded).weight(.semibold)
    }
}

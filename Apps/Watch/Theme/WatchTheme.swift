#if os(watchOS)
import SwiftUI

enum WatchTheme {
    static func color(_ token: SemanticColor) -> Color {
        switch token {
        case .neutral: return .cyan
        case .positive: return .green
        case .warning: return .yellow
        case .critical: return .red
        }
    }

    static let valueFont = Font.system(size: 30, weight: .semibold, design: .rounded)
}
#endif

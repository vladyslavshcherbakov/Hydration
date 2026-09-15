#if os(iOS)
import SwiftUI

enum PhoneTheme {
    static func color(_ token: SemanticColor) -> Color {
        switch token {
        case .neutral: return Color(red: 0.16, green: 0.45, blue: 0.85)
        case .positive: return Color(red: 0.13, green: 0.60, blue: 0.36)
        case .warning: return Color(red: 0.85, green: 0.58, blue: 0.13)
        case .critical: return Color(red: 0.78, green: 0.22, blue: 0.22)
        }
    }

    static let cornerRadius: CGFloat = 20
    static let ringWidth: CGFloat = 16
    static let titleFont = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let valueFont = Font.system(size: 44, weight: .semibold, design: .rounded)
}
#endif

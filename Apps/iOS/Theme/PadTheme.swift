#if os(iOS)
import UIKit

enum PadTheme {
    static func color(_ token: SemanticColor) -> UIColor {
        switch token {
        case .neutral: return UIColor.label
        case .positive: return UIColor.systemTeal
        case .warning: return UIColor.systemOrange
        case .critical: return UIColor.systemPink
        }
    }
}
#endif

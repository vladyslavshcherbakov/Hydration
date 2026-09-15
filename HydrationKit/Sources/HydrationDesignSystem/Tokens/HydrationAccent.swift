import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public enum HydrationAccent {
    #if os(iOS)
    public static func color(_ token: SemanticColor) -> Color {
        Color(uiColor: uiColor(token))
    }

    public static func uiColor(_ token: SemanticColor) -> UIColor {
        switch token {
        case .neutral: return .systemBlue
        case .positive: return .systemGreen
        case .warning: return .systemOrange
        case .critical: return .systemRed
        }
    }
    #else
    public static func color(_ token: SemanticColor) -> Color {
        switch token {
        case .neutral: return .blue
        case .positive: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
    #endif
}

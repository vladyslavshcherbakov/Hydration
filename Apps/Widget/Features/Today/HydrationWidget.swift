#if canImport(WidgetKit)
import HydrationDomain
import HydrationRouting
import SwiftUI
import WidgetKit

struct HydrationWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: HydrationEntry

    var body: some View {
        if #available(iOS 17.0, watchOS 10.0, *) {
            content.containerBackground(.fill.tertiary, for: .widget)
        } else {
            content.padding()
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.state.title).font(.caption).foregroundStyle(.secondary)
            Text(entry.state.totalText).font(.title2.weight(.semibold))
            Text(entry.state.goalText).font(.caption2).foregroundStyle(.secondary)
            ProgressView(value: entry.state.fraction).tint(WidgetTheme.color(entry.state.accent))
            Text(entry.state.statusText).font(.caption2)
            if !entry.state.footnote.isEmpty {
                Text(entry.state.footnote).font(.caption2).foregroundStyle(.tertiary)
            }
            if #available(iOS 17.0, *), family == .systemSmall, entry.state.isQuickAddEnabled {
                Button(intent: AddDrinkIntent(milliliters: Volume.quickAdd.milliliters)) {
                    Text(entry.state.quickAddTitle)
                }
                .buttonStyle(.bordered)
            }
        }
        .accessibilityLabel(entry.state.accessibilityLabel)
        .widgetURL(DeepLinkMapper.url(for: .history))
    }
}

enum WidgetTheme {
    static func color(_ token: SemanticColor) -> Color {
        switch token {
        case .neutral: return .blue
        case .positive: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

@main
struct HydrationWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: HydrationWidgetKind.today,
            provider: HydrationTimelineProvider(
                fetchProgress: WidgetComposition.fetchTodayProgress(),
                presenter: WidgetComposition.presenter(),
                dateProvider: WidgetComposition.dateProvider(),
                currentDay: WidgetComposition.currentDay(),
                log: WidgetComposition.log()
            )
        ) { entry in
            HydrationWidgetView(entry: entry)
        }
        .configurationDisplayName("Hydration")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}
#endif

#if canImport(WidgetKit)
import HydrationDesignSystem
import HydrationDomain
import HydrationRouting
import SwiftUI
import WidgetKit

struct HydrationWidgetView: View {
    @Environment(\.widgetFamily) private var family

    private let typography = HydrationTypography.widget

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
            Text(entry.state.title).font(typography.caption).foregroundStyle(.secondary)
            HydrationTotalLabel(
                total: entry.state.totalText,
                goal: entry.state.goalText,
                typography: .widget,
                layout: .stacked
            )
            HydrationProgressView(fraction: entry.state.fraction, accent: entry.state.accent, style: .bar)
            HydrationStatusLabel(text: entry.state.statusText, accent: entry.state.accent, typography: .widget)
            if !entry.state.footnote.isEmpty {
                Text(entry.state.footnote).font(typography.caption).foregroundStyle(.tertiary)
            }
            if #available(iOS 17.0, *), family == .systemSmall, entry.state.isQuickAddEnabled {
                Button(intent: AddDrinkIntent(milliliters: Volume.quickAdd.milliliters)) {
                    Text(entry.state.quickAddTitle)
                }
                .font(typography.action)
                .buttonStyle(.bordered)
            }
        }
        .accessibilityLabel(entry.state.accessibilityLabel)
        .widgetURL(DeepLinkMapper.url(for: .history))
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

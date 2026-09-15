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

    // MARK: - Public

    var body: some View {
        if #available(iOS 17.0, watchOS 10.0, *) {
            content.containerBackground(.fill.tertiary, for: .widget)
        } else {
            content.padding()
        }
    }

    // MARK: - Private

    private var content: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.viewData.title).font(typography.caption).foregroundStyle(.secondary)

            switch entry.viewData.state {
            case .content(let day): today(day)
            case .failed(let failure): problem(failure)
            }
        }
        .widgetURL(DeepLinkMapper.url(for: .history))
    }

    @ViewBuilder
    private func problem(_ failure: WidgetTodayViewData.Failure) -> some View {
        HydrationStatusLabel(text: failure.message, accent: failure.accent, typography: .widget)
            .accessibilityLabel(failure.accessibilityLabel)
    }

    @ViewBuilder
    private func today(_ day: WidgetTodayViewData.Content) -> some View {
        HydrationTotalLabel(
            total: day.totalText,
            goal: day.goalText,
            typography: .widget,
            layout: .stacked
        )
        HydrationProgressView(fraction: day.fraction, accent: day.accent, style: .bar)
        HydrationStatusLabel(text: day.statusText, accent: day.accent, typography: .widget)

        if !day.footnote.isEmpty {
            Text(day.footnote).font(typography.caption).foregroundStyle(.tertiary)
        }

        if #available(iOS 17.0, *), family == .systemSmall, day.isQuickAddEnabled {
            Button(intent: AddDrinkIntent(milliliters: Volume.quickAdd.milliliters)) {
                Text(day.quickAddTitle)
            }
            .font(typography.action)
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - HydrationWidget

@main
struct HydrationWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: HydrationWidgetKind.today,
            provider: HydrationTimelineProvider(
                fetchProgress: WidgetComposition.fetchTodayProgress(),
                mapper: WidgetComposition.mapper(),
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

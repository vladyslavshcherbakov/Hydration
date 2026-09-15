#if os(iOS)
import HydrationDesignSystem
import SwiftUI

struct HistoryScreen: View {
    @StateObject private var viewModel: HistoryViewModel
    @ObservedObject private var coordinator: AppCoordinator

    init(viewModel: @autoclosure @escaping () -> HistoryViewModel, coordinator: AppCoordinator) {
        _viewModel = StateObject(wrappedValue: viewModel())
        _coordinator = ObservedObject(wrappedValue: coordinator)
    }

    var body: some View {
        let viewData = viewModel.viewData

        List {
            switch viewData.state {
            case .loading: EmptyView()
            case .content(let content): days(content)
            case .failed(let message): Text(message).foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier("history.list")
        .navigationTitle(viewData.title)
        .onChange(of: coordinator.selectedDay) { day in
            viewModel.apply(selected: day)
        }
        .task { await viewModel.observe() }
    }

    // MARK: - Private

    private func days(_ content: HistoryViewData.Content) -> some View {
        Section(content.summaryText) {
            ForEach(content.rows) { row in
                Button {
                    viewModel.select(rowID: row.id)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(row.dayText).foregroundStyle(.primary)
                            Spacer()
                            if let badge = row.badgeText {
                                Text(badge)
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(HydrationAccent.color(row.accent).opacity(HydrationMetrics.badgeOpacity), in: Capsule())
                                    .foregroundStyle(HydrationAccent.color(row.accent))
                            }
                            Text(row.totalText).foregroundStyle(.secondary)
                            if row.isSelected {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(HydrationAccent.color(row.accent))
                            }
                        }
                        ProgressView(value: row.fraction)
                            .tint(HydrationAccent.color(row.accent))
                    }
                }
                .accessibilityIdentifier(row.identifier)
            }
        }
    }
}
#endif

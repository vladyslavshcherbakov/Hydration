#if os(iOS)
import SwiftUI

struct HistoryScreen: View {
    @StateObject private var viewModel: HistoryViewModel
    @ObservedObject private var coordinator: AppCoordinator

    init(viewModel: @autoclosure @escaping () -> HistoryViewModel, coordinator: AppCoordinator) {
        _viewModel = StateObject(wrappedValue: viewModel())
        _coordinator = ObservedObject(wrappedValue: coordinator)
    }

    var body: some View {
        let state = viewModel.state

        List {
            if let emptyText = state.emptyText {
                Text(emptyText).foregroundStyle(.secondary)
            } else {
                Section(state.summaryText) {
                    ForEach(state.rows) { row in
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
                                            .background(PhoneTheme.color(row.accent).opacity(0.18), in: Capsule())
                                            .foregroundStyle(PhoneTheme.color(row.accent))
                                    }
                                    Text(row.totalText).foregroundStyle(.secondary)
                                    if row.isSelected {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(PhoneTheme.color(row.accent))
                                    }
                                }
                                ProgressView(value: row.fraction)
                                    .tint(PhoneTheme.color(row.accent))
                            }
                        }
                        .accessibilityIdentifier(row.identifier)
                    }
                }
            }
        }
        .accessibilityIdentifier("history.list")
        .navigationTitle(state.title)
        .onChange(of: coordinator.selectedDay) { day in
            viewModel.apply(selected: day)
        }
        .task { await viewModel.observe() }
    }
}
#endif

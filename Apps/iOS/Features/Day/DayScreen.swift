#if os(iOS)
import HydrationDesignSystem
import SwiftUI

struct DayScreen: View {
    @StateObject private var viewModel: DayViewModel

    private let showsHistory: Bool

    init(viewModel: @autoclosure @escaping () -> DayViewModel, showsHistory: Bool) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.showsHistory = showsHistory
    }

    var body: some View {
        let state = viewModel.state

        List {
            Section {
                progress(state)
            }
            .listRowBackground(Color.clear)

            if state.entries.isEmpty {
                Section {
                    Text(state.footnote ?? "")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section(state.footnote ?? "") {
                    ForEach(state.entries) { entry in
                        HStack {
                            Text(entry.amountText)
                            Spacer()
                            Text(entry.timeText).foregroundStyle(.secondary)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await viewModel.remove(entryID: entry.id) }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(state.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if showsHistory {
                    Button(state.historyTitle) { viewModel.openHistory() }
                        .accessibilityIdentifier("today.history")
                }
            }
        }
        .task { await viewModel.observe() }
    }

    private func progress(_ state: DayViewState) -> some View {
        VStack(spacing: 24) {
            ZStack {
                HydrationProgressView(
                    fraction: state.fraction,
                    accent: state.accent,
                    style: .ring(diameter: HydrationMetrics.ringDiameter)
                )
                HydrationTotalLabel(
                    total: state.totalText,
                    goal: state.goalText,
                    typography: .phone,
                    layout: .stacked,
                    totalIdentifier: "today.total"
                )
            }

            HydrationStatusLabel(text: state.statusText, accent: state.accent, typography: .phone)

            HydrationActionButton(
                title: state.quickAddTitle,
                accent: state.accent,
                typography: .phone,
                prominence: .filled,
                isEnabled: state.isQuickAddEnabled
            ) {
                Task { await viewModel.quickAdd() }
            }
            .accessibilityIdentifier("today.quickAdd")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
#endif

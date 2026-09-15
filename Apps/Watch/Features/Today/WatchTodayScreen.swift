#if os(watchOS)
import HydrationDesignSystem
import SwiftUI

struct WatchTodayScreen: View {
    @StateObject private var viewModel: WatchTodayViewModel

    // MARK: - Public
    init(viewModel: @autoclosure @escaping () -> WatchTodayViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        let state = viewModel.state

        ScrollView {
            VStack(spacing: 10) {
                totals(state)
                HydrationProgressView(fraction: state.fraction, accent: state.accent, style: .bar)
                presets(state)
                undo(state)
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 6)
        }
        .accessibilityLabel(state.accessibilityLabel)
        .navigationTitle(state.title)
        .task { await viewModel.observe() }
    }

    // MARK: - Private
    private func totals(_ state: WatchTodayViewState) -> some View {
        VStack(spacing: 2) {
            HydrationTotalLabel(
                total: state.totalText,
                goal: state.goalText,
                typography: .watch,
                layout: .inline
            )
            HydrationStatusLabel(text: state.statusText, accent: state.accent, typography: .watch)
        }
        .frame(maxWidth: .infinity)
    }

    private func presets(_ state: WatchTodayViewState) -> some View {
        HStack(spacing: 4) {
            ForEach(state.presets) { preset in
                HydrationActionButton(
                    title: preset.title,
                    accent: state.accent,
                    typography: .watch,
                    prominence: .bordered,
                    isEnabled: preset.isEnabled
                ) {
                    Task { await viewModel.add(milliliters: preset.milliliters) }
                }
            }
        }
    }

    private func undo(_ state: WatchTodayViewState) -> some View {
        HydrationActionButton(
            title: state.undoTitle,
            accent: .critical,
            typography: .watch,
            prominence: .bordered,
            isEnabled: state.isUndoEnabled
        ) {
            Task { await viewModel.undoLast() }
        }
    }
}
#endif

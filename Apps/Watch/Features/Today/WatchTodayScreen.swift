#if os(watchOS)
import HydrationDesignSystem
import SwiftUI

struct WatchTodayScreen: View {
    @StateObject private var viewModel: WatchTodayViewModel

    init(viewModel: @autoclosure @escaping () -> WatchTodayViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        let state = viewModel.state

        ScrollView {
            switch state.situation {
            case .loading(let loading): waiting(loading)
            case .content(let content): today(content)
            case .failed(let failure): problem(failure)
            }
        }
        .navigationTitle(state.title)
        .task { await viewModel.observe() }
    }

    // MARK: - Private

    private func waiting(_ loading: WatchTodayViewState.Loading) -> some View {
        ProgressView()
            .accessibilityLabel(loading.accessibilityLabel)
    }

    private func problem(_ failure: WatchTodayViewState.Failure) -> some View {
        HydrationStatusLabel(text: failure.message, accent: failure.accent, typography: .watch)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .accessibilityLabel(failure.accessibilityLabel)
    }

    private func today(_ content: WatchTodayViewState.Content) -> some View {
        VStack(spacing: 10) {
            totals(content)
            HydrationProgressView(fraction: content.fraction, accent: content.accent, style: .bar)
            presets(content)
            undo(content)
        }
        .padding(.horizontal, 2)
        .padding(.bottom, 6)
        .accessibilityLabel(content.accessibilityLabel)
    }

    private func totals(_ content: WatchTodayViewState.Content) -> some View {
        VStack(spacing: 2) {
            HydrationTotalLabel(
                total: content.totalText,
                goal: content.goalText,
                typography: .watch,
                layout: .inline
            )
            HydrationStatusLabel(text: content.statusText, accent: content.accent, typography: .watch)
        }
        .frame(maxWidth: .infinity)
    }

    private func presets(_ content: WatchTodayViewState.Content) -> some View {
        HStack(spacing: 4) {
            ForEach(content.presets) { preset in
                HydrationActionButton(
                    title: preset.title,
                    accent: content.accent,
                    typography: .watch,
                    prominence: .bordered,
                    isEnabled: preset.isEnabled
                ) {
                    Task { await viewModel.add(milliliters: preset.milliliters) }
                }
            }
        }
    }

    private func undo(_ content: WatchTodayViewState.Content) -> some View {
        HydrationActionButton(
            title: content.undoTitle,
            accent: .critical,
            typography: .watch,
            prominence: .bordered,
            isEnabled: content.isUndoEnabled
        ) {
            Task { await viewModel.undoLast() }
        }
    }
}
#endif

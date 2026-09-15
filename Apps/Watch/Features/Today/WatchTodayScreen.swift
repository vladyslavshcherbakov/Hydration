#if os(watchOS)
import SwiftUI

struct WatchTodayScreen: View {
    @StateObject private var viewModel: WatchTodayViewModel

    init(viewModel: @autoclosure @escaping () -> WatchTodayViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        let state = viewModel.state

        ScrollView {
            VStack(spacing: 10) {
                totals(state)
                ProgressView(value: min(state.fraction, 1))
                    .tint(WatchTheme.color(state.accent))
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

    private func totals(_ state: WatchTodayViewState) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(state.totalText)
                    .font(WatchTheme.valueFont)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(state.goalText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Text(state.statusText)
                .font(.footnote)
                .foregroundStyle(WatchTheme.color(state.accent))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private func presets(_ state: WatchTodayViewState) -> some View {
        HStack(spacing: 4) {
            ForEach(state.presets) { preset in
                Button(preset.title) {
                    Task { await viewModel.add(milliliters: preset.milliliters) }
                }
                .font(.body.weight(.semibold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .buttonStyle(.bordered)
                .tint(WatchTheme.color(state.accent))
                .disabled(!preset.isEnabled)
            }
        }
    }

    private func undo(_ state: WatchTodayViewState) -> some View {
        Button(state.undoTitle, role: .destructive) {
            Task { await viewModel.undoLast() }
        }
        .font(.footnote)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .buttonStyle(.bordered)
        .disabled(!state.isUndoEnabled)
    }
}
#endif

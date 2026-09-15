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
        let viewData = viewModel.viewData

        List {
            switch viewData.state {
            case .loading(let loading): waiting(loading)
            case .content(let content): day(content)
            case .failed(let failure): problem(failure)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(viewData.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if showsHistory {
                    Button(viewData.historyTitle) { viewModel.openHistory() }
                        .accessibilityIdentifier("today.history")
                }
            }
        }
        .task { await viewModel.observe() }
        .alert(
            viewModel.notice ?? "",
            isPresented: Binding(
                get: { viewModel.notice != nil },
                set: { isPresented in
                    guard !isPresented else { return }
                    viewModel.dismissNotice()
                }
            )
        ) {
            Button("OK") { viewModel.dismissNotice() }
        }
    }

    // MARK: - Private

    @ViewBuilder
    private func waiting(_ loading: DayViewData.Loading) -> some View {
        Section {
            Text(loading.message).foregroundStyle(.secondary)
        }
        .accessibilityLabel(loading.accessibilityLabel)
    }

    @ViewBuilder
    private func problem(_ failure: DayViewData.Failure) -> some View {
        Section {
            HydrationStatusLabel(text: failure.message, accent: failure.accent, typography: .phone)

            HydrationActionButton(
                title: failure.retryTitle,
                accent: failure.accent,
                typography: .phone,
                prominence: .filled,
                isEnabled: true
            ) {
                Task { await viewModel.load() }
            }
            .accessibilityIdentifier("today.retry")
        }
        .accessibilityLabel(failure.accessibilityLabel)
    }

    @ViewBuilder
    private func day(_ content: DayViewData.Content) -> some View {
        Section {
            progress(content)
        }
        .listRowBackground(Color.clear)

        if content.entries.isEmpty {
            Section {
                Text(content.footnote).foregroundStyle(.secondary)
            }
        } else {
            Section(content.footnote) {
                ForEach(content.entries) { entry in
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

    private func progress(_ content: DayViewData.Content) -> some View {
        VStack(spacing: 24) {
            ZStack {
                HydrationProgressView(
                    fraction: content.fraction,
                    accent: content.accent,
                    style: .ring(diameter: HydrationMetrics.ringDiameter)
                )
                HydrationTotalLabel(
                    total: content.totalText,
                    goal: content.goalText,
                    typography: .phone,
                    layout: .stacked,
                    totalIdentifier: "today.total"
                )
            }

            HydrationStatusLabel(text: content.statusText, accent: content.accent, typography: .phone)

            HydrationActionButton(
                title: content.quickAddTitle,
                accent: content.accent,
                typography: .phone,
                prominence: .filled,
                isEnabled: content.isQuickAddEnabled
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

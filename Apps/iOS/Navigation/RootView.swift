#if os(iOS)
import SwiftUI

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var coordinator: AppCoordinator

    let factory: ScreenFactory

    var body: some View {
        content
            .onAppear { coordinator.apply(layout: preferredLayout) }
            .onChange(of: horizontalSizeClass) { _ in coordinator.apply(layout: preferredLayout) }
    }

    private var preferredLayout: AppCoordinator.Layout {
        horizontalSizeClass == .regular ? .split : .stack
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.layout {
        case .split:
            NavigationSplitView {
                NavigationStack {
                    if let route = coordinator.detail {
                        factory.makeDetailScreen(for: route)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "drop")
                            Text("Nothing selected")
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            } detail: {
                NavigationStack {
                    factory.makeDayScreen(showsHistory: false)
                        .id(coordinator.selectedDay)
                }
            }
        case .stack:
            NavigationStack(path: $coordinator.path) {
                factory.makeDayScreen(showsHistory: true)
                    .id(coordinator.selectedDay)
                    .navigationDestination(for: AppRoute.self) { route in
                        factory.makeStackScreen(for: route)
                    }
            }
        }
    }
}
#endif

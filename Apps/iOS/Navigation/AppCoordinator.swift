import Foundation
import HydrationDomain

public enum AppRoute: Hashable, Sendable {
    case history
}

// MARK: - AppCoordinator

@MainActor
public final class AppCoordinator: ObservableObject {

    // MARK: - Layout

    public enum Layout: Equatable, Sendable {
        case stack
        case split
    }

    @Published public var path: [AppRoute] = []
    @Published public var detail: AppRoute?
    @Published public private(set) var selectedDay: Date
    @Published public private(set) var layout: Layout

    public init(layout: Layout = .stack, selectedDay: Date) {
        self.layout = layout
        self.selectedDay = selectedDay
        self.detail = layout == .split ? .history : nil
    }

    public var visibleRoute: AppRoute? {
        switch layout {
        case .stack: return path.last
        case .split: return detail
        }
    }

    public func show(_ route: AppRoute) {
        switch layout {
        case .stack:
            guard path.last != route else { return }
            path.append(route)
        case .split:
            guard detail != route else { return }
            detail = route
        }
    }

    public func select(day: Date) {
        selectedDay = day
        guard layout == .stack else { return }
        path.removeAll()
    }

    public func pop() {
        switch layout {
        case .stack:
            guard !path.isEmpty else { return }
            path.removeLast()
        case .split:
            detail = nil
        }
    }

    public func popToRoot() {
        path.removeAll()
        detail = layout == .split ? .history : nil
    }

    public func apply(layout newLayout: Layout) {
        guard newLayout != layout else { return }
        let visible = visibleRoute
        layout = newLayout

        switch newLayout {
        case .stack:
            detail = nil
            path = visible.map { [$0] } ?? []
        case .split:
            path = []
            detail = visible ?? .history
        }
    }
}

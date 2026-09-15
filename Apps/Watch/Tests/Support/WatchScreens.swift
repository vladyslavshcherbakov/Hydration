import Foundation
import HydrationTestSupport
@testable import HydrationWatch

// MARK: - WatchGraphEnvironment

@MainActor
extension WatchGraphEnvironment {
    func todayScreen() -> WatchTodayViewModel {
        graph.makeTodayViewModel()
    }
}

import Foundation
import HydrationDomain
import HydrationRouting

@MainActor
public final class DeepLinkOpener {
    private let coordinator: AppCoordinator
    private let addDrink: AddDrinkUseCase
    private let currentDay: CurrentDay
    private let log: HydrationLog

    // MARK: - Public

    public init(coordinator: AppCoordinator, addDrink: AddDrinkUseCase, currentDay: CurrentDay, log: HydrationLog) {
        self.coordinator = coordinator
        self.addDrink = addDrink
        self.currentDay = currentDay
        self.log = log
    }

    @discardableResult
    public func open(_ link: DeepLink) async -> DeepLinkOutcome {
        switch link {
        case .today:
            log.write(.info, "a link opened today")
            coordinator.popToRoot()
            return .handled
        case .history:
            log.write(.info, "a link opened history")
            coordinator.show(.history)
            return .handled
        case .addDrink(let milliliters):
            return await addDrinkAndShowToday(milliliters: milliliters)
        }
    }

    @discardableResult
    public func open(_ url: URL) async -> DeepLinkOutcome? {
        guard let link = DeepLinkMapper.link(from: url) else {
            log.write(.warning, "link \(url.absoluteString) is not one this app understands")
            return nil
        }
        return await open(link)
    }

    // MARK: - Private

    private func addDrinkAndShowToday(milliliters: Int) async -> DeepLinkOutcome {
        coordinator.popToRoot()
        do {
            _ = try await addDrink.execute(milliliters: milliliters, on: currentDay.start())
            return .handled
        } catch let error as HydrationError {
            log.write(.warning, "link asking for \(milliliters) ml was refused: \(error)")
            return .rejected(error)
        } catch {
            log.write(.error, "link asking for \(milliliters) ml could not be stored: \(error)")
            return .rejected(.storageUnavailable)
        }
    }
}

#if canImport(AppIntents) && canImport(WidgetKit)
import AppIntents
import Foundation
import HydrationRouting
import WidgetKit

@available(iOS 17.0, watchOS 10.0, *)
struct AddDrinkIntent: AppIntent {
    static var title: LocalizedStringResource = "Log water"

    @Parameter(title: "Amount in milliliters")
    var milliliters: Int

    init() {}

    init(milliliters: Int) {
        self.milliliters = milliliters
    }

    func perform() async throws -> some IntentResult {
        try await logDrink(into: WidgetComposition.currentDay().start())
        WidgetCenter.shared.reloadTimelines(ofKind: HydrationWidgetKind.today)
        return .result()
    }

    private func logDrink(into day: Date) async throws {
        let log = WidgetComposition.log()
        do {
            _ = try await WidgetComposition.addDrink().execute(milliliters: milliliters, on: day)
            log.write(.info, "the widget button logged \(milliliters) ml into \(day)")
        } catch {
            log.write(.error, "the widget button could not log \(milliliters) ml into \(day): \(error)")
            throw error
        }
    }
}
#endif

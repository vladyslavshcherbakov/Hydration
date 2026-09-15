#if canImport(AppIntents) && canImport(WidgetKit)
import AppIntents
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
        let today = WidgetComposition.currentDay().start()
        _ = try await WidgetComposition.addDrink().execute(milliliters: milliliters, on: today)
        WidgetCenter.shared.reloadTimelines(ofKind: HydrationWidgetKind.today)
        return .result()
    }
}
#endif

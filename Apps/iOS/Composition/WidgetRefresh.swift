#if os(iOS)
import Foundation
import HydrationDomain
import HydrationRouting
import WidgetKit

public struct WidgetRefresh: Sendable {
    private let kind: String
    private let log: HydrationLog

    public init(kind: String = HydrationWidgetKind.today, log: HydrationLog) {
        self.kind = kind
        self.log = log
    }

    public func reload() async {
        guard await isInstalled() else { return }
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }

    private func isInstalled() async -> Bool {
        await installedWidgets().contains { $0.kind == kind }
    }

    private func installedWidgets() async -> [WidgetInfo] {
        await withCheckedContinuation { continuation in
            WidgetCenter.shared.getCurrentConfigurations { result in
                switch result {
                case .success(let widgets):
                    continuation.resume(returning: widgets)
                case .failure(let error):
                    log.write(.warning, "the installed widgets could not be read, skipping the refresh: \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }
}
#endif

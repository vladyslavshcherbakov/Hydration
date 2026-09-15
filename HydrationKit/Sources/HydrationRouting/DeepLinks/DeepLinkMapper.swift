import Foundation
import HydrationDomain

public enum DeepLinkMapper {
    public static let scheme = "hydration"

    private enum Host: String {
        case today
        case history
        case add
    }

    private static let amountKey = "ml"

    public static func url(for link: DeepLink) -> URL {
        var components = URLComponents()
        components.scheme = scheme

        switch link {
        case .today:
            components.host = Host.today.rawValue
        case .history:
            components.host = Host.history.rawValue
        case .addDrink(let milliliters):
            components.host = Host.add.rawValue
            components.queryItems = [URLQueryItem(name: amountKey, value: String(milliliters))]
        }

        return components.url ?? URL(string: "\(scheme)://\(Host.today.rawValue)")!
    }

    public static func link(from url: URL) -> DeepLink? {
        guard url.scheme == scheme,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host.flatMap(Host.init(rawValue:)) else {
            return nil
        }

        switch host {
        case .today:
            return .today
        case .history:
            return .history
        case .add:
            guard let raw = components.queryItems?.first(where: { $0.name == amountKey })?.value,
                  let milliliters = Int(raw),
                  let volume = Volume(milliliters: milliliters),
                  volume > .zero else {
                return nil
            }
            return .addDrink(milliliters: milliliters)
        }
    }
}

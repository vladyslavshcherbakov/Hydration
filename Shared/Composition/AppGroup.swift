import Foundation

enum AppGroup {
    static let identifier: String = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String,
              !value.isEmpty else {
            preconditionFailure("AppGroupIdentifier is missing from Info.plist")
        }
        return value
    }()
}

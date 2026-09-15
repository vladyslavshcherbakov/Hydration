import Foundation
import HydrationDomain

struct SystemDateProvider: DateProvider {
    func now() -> Date {
        Date()
    }
}

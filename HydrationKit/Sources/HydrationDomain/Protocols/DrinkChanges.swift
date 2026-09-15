public protocol DrinkChanges: Sendable {
    func whenDrinksChange() -> AsyncStream<Void>
}

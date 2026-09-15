# Hydration

A water tracking app. Someone who wants to drink enough water during the day logs each glass in two taps, sees whether they are ahead or behind for the time of day, and looks back over the last two weeks. It is logged from whichever device is closest: the phone, the watch, or the home screen widget.

The project also exists to be read. It is a worked example of a clean layering on Apple platforms, so a rule that makes the code clearer wins over a rule that makes it shorter.

## Constraints

Platforms and minimum OS: iOS 16, watchOS 9. Swift 5.9.
Targets: `Hydration` (iOS app), `HydrationWatch` (watch app), `HydrationWidget` (widget extension).
Shared storage: the iOS app and the widget share one App Group container. The watch has its own storage on its own device and receives changes over WatchConnectivity.
Build system: XcodeGen, `project.yml`. No other tooling.

## Rules chosen

Shared code becomes a module in `HydrationKit` only when two or more production targets use it. Code used by several apps that is not a module lives in `Shared`.
Naming: plain English, no comments or documentation comments, one level of abstraction per function. The one comment the project uses is `MARK:`, separating a type's public section from its private one and naming every nested type and extension in a file.
Tests: behaviour through a real screen, one bundle per app, named `test_subject_whenCondition_outcome`. A module gets its own test target only for behaviour no screen can reach, such as a stored row the app is unable to write; the `Hydration` scheme runs those alongside the app bundles.
Commits: Conventional Commits. A subject line of `type(scope): summary`, in the imperative, under 72 characters, no full stop. Types are `feat`, `fix`, `refactor`, `test`, `docs`, `build` and `chore`. Scopes name where the change lands: `domain`, `persistence`, `paired-device`, `design-system`, `routing`, `test-support`, `ios`, `watch`, `widget`, `project`. The body wraps at 72 columns and says why rather than what, the diff already says what. A change to the paired device's wire format or to the stored schema carries a `BREAKING CHANGE:` footer saying what stops understanding what. Trailers come last.
Logging: through the `HydrationLog` protocol in the domain. No platform logging framework inside a layer. Every line carries a timestamp, and a function with more than one way out says which one it took, so a silent early return is never mistaken for a call that never happened.
Colours, fonts and shared visual components live once in `HydrationDesignSystem`. A surface names a token, never a colour value or a point size. Colours are the platform's system colours, so every surface follows the chosen theme.
The quick-add amount, the daily goal, and the safety limit are domain values, not UI constants.

## How the project is put together

Four layers, and a rule only ever lives in one of them.

Domain is `HydrationKit/Sources/HydrationDomain`, imports nothing. `Entities` holds the values, `Protocols` holds what the domain needs from the outside, `UseCases` holds one type per thing the user can do. Volumes, the daily goal, the safety limit and what counts as behind schedule live here and nowhere else.

Data is `HydrationPersistence` over Core Data and `HydrationPairedDevice` over WatchConnectivity. Both implement domain protocols, and both keep their framework types inside: a managed object or a message dictionary never leaves the module, a value does. Repositories here are stacked as decorators, each adding one effect to every write.

Presentation is per surface, inside each app under `Features/<feature>`. A presenter turns a domain value into a view state with every string already formatted, a view model owns the loading and holds the state, a view renders it and sends intents. The same use case feeds the phone, the watch and the widget through three presenters.

The look is shared. `HydrationDesignSystem` holds the tokens, `SemanticColor`, `HydrationAccent`, `HydrationTypography` and `HydrationMetrics`, and the components every surface draws with: a progress view as a ring or a bar, a total label stacked or in a line, a status label and an action button. A component takes a configuration where the surfaces genuinely differ. An element only one surface has stays in that app.

Composition is `Shared/Composition` plus one file per app. It creates the real implementations, stacks the decorators and hands them in. It is the only place that knows concrete types.

Modules exist only where two or more production targets need the code. Code shared by apps that is not a module lives in `Shared`.

## Where things are

`Apps/iOS` is the phone and iPad app: the day screen, history, navigation through `AppCoordinator`, deep links, widget refresh. `Apps/Watch` is the companion. `Apps/Widget` is the extension. Each owns its `Tests` and its generated configuration.

`HydrationKit` holds `HydrationDomain`, `HydrationPersistence`, `HydrationPairedDevice`, `HydrationRouting` for deep links, `HydrationDesignSystem` for the tokens and the shared components, and `HydrationTestSupport` for the shared test environment and doubles.

## What the apps do

Log a drink, undo or delete one, see the day's total against the goal and whether it is behind schedule for the time of day, look back over fourteen days, and pick an earlier day to log into. The phone and the watch each keep their own storage and exchange changes. The widget shares the phone's storage and can log a drink itself.

## Adding, changing and removing

A new thing the user can do is a use case in the domain plus a presenter and view state per surface that shows it. Rules go in the use case, never in a presenter or a view.

A new surface reuses the existing use cases and gets its own presenter, view state and view model. Do not widen an existing view state to serve two surfaces.

A new effect on every write is a repository decorator in composition, not a call added to each caller.

Removing a feature means removing its use case, its presenters and view states, and its tests. A domain type with no use case left is dead.

Whatever is added or removed, update the two sections above in broad strokes only. They are a map for finding things, not a changelog: a new screen or module belongs there, a renamed method does not.

## How current the data must be

Every surface shows the day's drinks, and four things write them: the phone screen, the watch, the widget's button, and a second window on iPad. The requirement is the same everywhere: the surface is right at the moment the data changes, not on a schedule.

- The phone and watch screens subscribe. `ObservedDrinkRepository` announces every write that goes through it, and each view model reloads on the announcement.
- The widget is reloaded by `WidgetRefreshingDrinkRepository`, which wraps the same storage, so a write from any source in the app's process reloads it, including one that arrived from the watch.
- A change is sent to the paired device as a message when it is reachable, and queued for later delivery when it is not. A queued transfer is what carries a change to a device that is not running, and its arrival is logged on the sending side.
- The phone is where today comes from. When it becomes active, and when the watch becomes reachable, it sends its picture of today: the day and every drink in it. The watch replaces its own day with that picture, so a drink the phone no longer holds disappears from the watch. The watch never sends a picture back; it sends the drinks it logs and the ones it undoes, one change at a time.
- A write another process made while the app was away is announced once, when the scene becomes active.
- The watch receives every write the app makes, and receives the widget's writes when the app next becomes active.

The timeline also refreshes every fifteen minutes. That is the fallback for a phone whose app has not run, not the mechanism.

Not guaranteed by this project: iOS decides whether to wake the app in the background to deliver a queued transfer from the watch. If it does not, the drink arrives at the next launch and the widget shows its last state until then. Only a device can show which happens.

## Accepted limits

`AddDrinkUseCase` reads the day, checks the six-litre limit, and writes, with a gap in between. Two devices adding at the same moment can both pass a check only one of them should pass. Accepted: one person with two devices, and the limit is a guard rail rather than a medical threshold.

A drink logged on the watch reaches the phone as a change, live or queued. If that change never arrives, the phone's next picture of today deletes it from the watch. Accepted: the phone is the one place today is decided, and a drink that never left the watch is lost rather than resurrected on both devices.

The picture covers today only. A drink logged into an earlier day travels as a single change and nothing repairs it if that change is lost.

While the phone app is not running, the watch keeps showing its own day. It gets the phone's picture when the phone app next runs.

## Open questions

None open.

## Decided

The widget has no WatchConnectivity session, so a drink logged there does not reach the watch when it is written. The iOS app sends its picture of today to the watch every time it becomes active, and the widget's writes travel with it.

Deletions are not kept anywhere. A day is made to agree by replacing it, not by merging it, so no record of what was deleted is needed. Only one side may replace, otherwise two devices swap days forever instead of agreeing, and that side is the phone.

A message on the link is one encoded value carrying a version and one of three contents: a drink, a removal, or a picture of a day. Its fields are not optional, because a drink always has an amount and a removal always has an identifier. What can be absent is the whole message, and reading it either yields a value or throws with the field it could not read.

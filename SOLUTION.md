# Solution notes

## Running it

- Xcode 26 or newer, iOS 26 simulator.
- Open `Tahudu.xcodeproj`, select the **Tahudu** scheme and an iPhone simulator, and press ⌘R. ⌘U runs all tests.
- Nothing to install or configure. The build runs no scripts and downloads no packages, and no Git hooks are active in a fresh clone. To run on a physical device, choose your own team under Signing & Capabilities.
- No third-party app libraries. The Tuist-generated project is included, so generation and tooling installation are optional for reviewers. Contributor setup, version pins, hooks, Fastlane and CI are described in [Tooling/README.md](Tooling/README.md).

## What's implemented

| Task | Summary |
| --- | --- |
| 1 — Search UI | Rebuilt in SwiftUI from the screenshot. The header is pinned and results scroll beneath it. Fonts follow the brief (tags `.caption2`, price `.headline`, card text `.caption`), and spacing and corner radii are multiples of 4. Contact buttons log a short statement to the console through the injected logger. |
| 2 — Live data | Listings come from the endpoint via `URLSession` + `async/await` and drive tags, metadata, contact buttons, the carousel, relative publish dates and the optional "Last contacted" banner. `bedrooms: null` renders as Studio. |
| 3 — Favourites | The heart on a card toggles a favourite, and favourites persist locally. The star in the header filters to favourites; while it's on, the star is filled, a "★ 2 saved properties · Show all" bar appears under the search field, and the list is tinted. Removing the last favourite shows an empty state with a way back. |
| Bonus — Settings | Refactored in UIKit behind the existing SwiftUI wrapper. One row model drives the table, platform defaults handle appearance, and XCTest covers configuration and selection. See below. |

Extras: text search over location and type, property-type and bedroom filters with a live result count, sorting, pull to refresh, and support for Dynamic Type (including accessibility sizes), VoiceOver labels and 44pt tap targets.

## Architecture

```
Tahudu (app, composition root)
├─ AppFactory                   owns the shared services (HTTP client, UserDefaults, logger); creates feature screens
├─ AppCoordinator               tab navigation; asks the factory for each tab's screen
└─ TahuduTabView
PropertyFinderKit (local Swift package)
├─ Features/
│  ├─ Listings
│  │  ├─ ListingsFactory        public entry point; builds the feature's screens
│  │  ├─ Domain/                models, errors, repository contracts, use cases, Mocks/ (sample listings)
│  │  ├─ Data/
│  │  │  ├─ Endpoints/          ListingsEndpoint (base URL, path and method of each call)
│  │  │  ├─ DTOs/               API shapes + toDomainModel()
│  │  │  ├─ DataSources/        ListingsRemoteDataSource (HTTP), FavouritesLocalDataSource (UserDefaults)
│  │  │  └─ Repositories/       ListingsRepository, FavouritesRepository
│  │  └─ Presentation/          ListingsView, ListingsViewModel, ListingsViewState, ListingCardViewData, Components/ (SearchHeader, ListingsContent, ListingCard, ListingPhotos, FiltersSheet), Mocks/ (view model and cards for previews)
│  └─ Settings                  UIKit screen: SettingsRow (rows and their actions), SettingsViewController, SettingsView (SwiftUI wrapper)
├─ DesignSystem                 Colors/, Typography/, Images/, Components/, Resources/ (the only UI asset catalog)
├─ Networking                   Endpoint protocol; HTTPClient sends requests and decodes JSON
├─ Logger                       LoggerProtocol + AppLogger over the unified log
└─ Extensions                   generic Foundation and SwiftUI helpers
```

The Listings feature's main screen is `ListingsView`: the results list, with a search header for text search, filters, sorting and the favourites filter. Search is one capability of that screen, so it names the header section and the `ListingSearchCriteria` it edits rather than the screen; the tab keeps the design's "Search" label. Further screens (listing details, saved listings) would sit beside it in `Presentation/` and reuse the same domain and data layers.

Composition: `TahuduApp` creates the `AppCoordinator` with an `AppFactory`. The factory builds the shared services itself (one HTTP client, `UserDefaults`, a logger). When the tab view asks the coordinator for a tab's screen, the factory creates that feature's factory (for example `ListingsFactory`, given those services) and returns the screen. API details stay in the data layer: each feature declares its endpoints (`ListingsEndpoint`) with a path and an HTTP method, overriding the shared base URL only for another host. The HTTP client always asks for JSON, validates the status code and decodes the DTO, so a data source only names the endpoint and the type it expects. Inside the feature:
`ListingsView → ListingsViewModel → use cases → repository contracts (Domain) ← ListingsRepository / FavouritesRepository → data sources → HTTPClient / UserDefaults`.

Repositories are named after the domain data they provide and implement the Domain contracts; data sources are named after where the data lives. A repository maps DTOs to domain models and transport errors to domain errors, so nothing above the Data layer sees JSON, HTTP or `UserDefaults`.

Key decisions:

- **The view only renders.** The view model publishes one `state` value (loading, failed, no listings, no favourites, no matches, or results as display-ready `ListingCardViewData`), so the view makes no decisions. `ListingCardViewData(listing:isFavourite:)` turns a listing into card text with Foundation format styles, so the view model holds no formatters; both are unit-tested. The search controls edit the view model's `criteria` directly, and the results are derived from it.
- **Few, purposeful views.** Small pieces of a body are computed properties on their view. A large piece becomes its own view in `Presentation/Components/` only when that limits what redraws: `SearchHeader` and `ListingsContent` observe different state, so typing redraws them but not the `ListingsView` root; each `ListingCard` redraws only when its own data changes; `ListingPhotos` and `FiltersSheet` own their own state.
- **Native refresh.** Initial loading and load failures sit outside the scrollable list, so pulling cannot display a second spinner during the first request. After a successful load, results and empty states share one native `List`, preserving search focus and pull-to-refresh. Its refresh action awaits the complete fetch; row insets and hidden separators preserve the card layout.
- **Screen state.** One standalone `ListingsViewState` describes loading, failure, results and the distinct empty states. The view-model protocol exposes this presentation type without referencing its implementation. The view model keeps the original listings private and derives the displayed cards when data, favourites or search criteria change; failed refreshes preserve the current results.
- **Loading.** A view-scoped `.task` calls `load()`, which does nothing once listings have loaded. Retry changes a view-owned trigger to restart that same `.task`, which calls `load()` again and shows loading until the new request finishes. Leaving the screen cancels initial loads and retries consistently. The initial `.task` and native `.refreshable` action await the fetch directly, so cancellation follows the calling task without a shared unstructured task or cancellation handler. Refresh is available only after the first successful load; the native refresh control manages its gesture and spinner until its action returns. A new view load can start if an earlier cancelled request is still unwinding; its cancelled response cannot replace the current data. Cancellation is never shown as an error, and a failed pull-to-refresh keeps the current list with a non-blocking inline message. Fetching uses `async throws` directly, with no presentation-layer `Result` wrapper or request counter.
- **Keyboard.** `ListingsView` owns the search field's focus. The entire padded input can receive focus, and its decorative border does not intercept touches. Header buttons dismiss focus explicitly in their actions; results taps, Return, Clear, choosing a sort order and scrolling also end typing. Text bindings use explicit getters and setters against the view-model protocol.
- **Previews.** Previews use `ListingsViewModelMock` and the sample `Listing.mocks` / `ListingCardViewData.mocks`, compiled only in Debug, so a view file never builds repositories or use cases. Tests share `Listing.mock(...)`.
- **Decoding.** The `{ "listings": [...] }` envelope uses a normal `[ListingDTO]` with synthesized `Decodable`. A missing required field, wrong type or invalid date rejects the response and shows the existing error/retry state. After decoding, the repository drops blank IDs and keeps the first occurrence of duplicate IDs so favourites and list identity stay unambiguous.
- **Favourites.** The view model holds a `Set<String>` for unique IDs and membership checks. Persistence converts it to an array of strings under one `UserDefaults` key; toggling one favourite saves the updated collection. The favourites filter is session state and resets on launch.
- **Errors.** Domain declares `ListingsError`, named for what failed rather than for the layer that reports it. Data maps transport and decoding failures to its cases. Presentation owns explicit English messages in `ListingsError+Extension.swift`; Domain contains no UI copy or transport dependencies. Layer ownership takes precedence over keeping every extension beside the type declaration.
- **Queries.** Default criteria return the feed unchanged without filtering or sorting. Active criteria use one filter pass that checks favourites, property type and bedrooms with a guard, then matches search tokens. A small private switch handles the any/studio/count bedroom rule; the chosen sort runs after filtering. Swift's stable sort keeps feed order for ties; price sorting groups currencies without inventing exchange rates.
- **Pagination.** The supplied API documents one JSON feed. Eleven pagination query formats (including page/limit, offset/limit, cursor, nested paging keys and an out-of-range page) and item/byte range requests all returned the identical 42 listings, with no paging links or metadata. No supported server pagination was found. Client-side slicing would not reduce the 15,759-byte uncompressed download, so the app keeps the full feed and renders rows lazily.
- **Timeouts.** The HTTP client uses URLSession defaults: a 60-second request inactivity timeout and a 7-day resource timeout. There is no endpoint requirement or measured basis for custom timeout values in this task. The injected-session initializer remains available for callers that supply a session.
- **HTTP caching.** The app injects a `URLSession(configuration: .default)` into the HTTP client. The default `.useProtocolCachePolicy` and shared `URLCache` already provide HTTP caching and validation; there is no custom configuration factory or arbitrary cache sizing. Capacity, eviction and sharing now follow the system defaults. The supplied endpoint sends an `ETag` with `Cache-Control: public, max-age=0, must-revalidate`; a default-session probe confirmed automatic validation and delivery of cached JSON as a successful response. This saves retransferring an unchanged body while still checking with the server. No custom expiry, permanent offline guarantee or manual 304 handling is added.
- **Concurrency.** Swift 6 language mode with complete concurrency checking. The UI-only app target defaults to MainActor isolation. Feature and shared package targets stay nonisolated by default. UI state is explicitly `@MainActor`. The synchronous favourites data source, repository, load and toggle protocols share MainActor isolation, allowing small reads and updates from the UI without actor hops or unchecked sendability; this is an implementation choice, not a UserDefaults requirement. Their immutable wrappers inherit isolation for the conforming methods and need no duplicate type annotation. Fetching is asynchronous and Sendable; querying is a stateless Sendable value operation and runs on its caller’s actor. Protocol conformance in an extension isolates that extension, not the entire type, so the stateful view model retains its own annotation to protect stored state and private helpers. Cross-isolation data is `Sendable`.
- **Conformance style.** Views and the `App` declare their conformance on the type, with `body` inside the main declaration; that conformance also makes them main-actor isolated. Other conformances with implemented methods or computed properties go in same-file extensions, keeping private helpers on the main declaration. Put conformances with no implementation to group (including synthesized conformances) on the type itself, avoiding empty extensions. Stored properties and enum raw types remain in declarations. The presentation-owned error descriptions are a deliberate layer-based exception to co-location. The Settings controller keeps the supplied placeholder actions in their original extension, unchanged.
- **Modules.** Each feature owns its layers; shared modules know nothing about listings. The app sees only each feature's factory and screens; domain and data types stay internal.
- **Assets.** The app's catalog holds only the app icon, which Xcode requires in the app target. Every colour, symbol and image the UI uses lives in `DesignSystem` under semantic names such as `success` and `noticeBackground`, so features share one catalog. Both carousel photos have 1×, 2× and 3× renditions. The smaller variants are downsampled directly from each original 3× JPEG; the original files are preserved, with pixel dimensions rounded to whole pixels.
- **Logging privacy.** The logger uses the previous string-based API with `LogPrivacy`. Complete messages are private by default, so collected logs normally show `<private>`; a caller can explicitly use `privacy: .public` for safe diagnostics. Private values may still be visible while debugging. Debug, info and error use their native unified-log levels in both configurations; visibility, persistence and retention follow the system logging policy.
- **English-only UI.** The app fixes its SwiftUI locale to `en_AE` and layout direction to left-to-right. Card dates/numbers use an explicit English locale, filter choices use ordinary sorting, and error messages are English strings. There are no translation catalogs or localization TODOs, and automatic string extraction is disabled. The UIKit Settings language row displays "English".
- **Touch targets.** The shared `expandingHitArea` helper enforces a 44pt minimum before applying its rectangular hit shape, including for caption-sized summary actions and the input clear button.
- **Spacing.** `DesignSystem.Spacing` provides package-scoped point values (`pt4`, `pt8`, `pt12`, `pt16`, `pt24`, `pt32`, `pt48`). Listings and the shared input use them for gaps, padding, insets and offsets. Control sizes, corner radii and content-width limits retain their separate layout meanings.
- **Photos.** Zero or one image uses a static photo or placeholder. Only multiple images create a carousel, page dots and VoiceOver adjustment actions, keeping empty arrays out of page-index calculations.
- **Text roles.** The brief's font rules are design-system tokens: `Font.badge` (`.caption2`), `Font.prominentValue` (`.headline`) and `Font.detail` (`.caption`), all built on Dynamic Type.
- **Privacy manifest.** `Tahudu/PrivacyInfo.xcprivacy` declares the app's `UserDefaults` use (reason `CA92.1`: the app's own data), which the App Store requires.

## Interpretations

- The API sends `first_image` / `second_image`, while the README says `FirstImage` / `SecondImage`. Both names are accepted, and unknown names show a placeholder.
- "N Beds" is written as "1 Bed" / "2 Beds", consistent with "1 Bath" / "2 Baths".
- `priceInclusive` is decoded but not shown: the design doesn't show it, and the brief doesn't say what it includes.
- Location, bathrooms and area are shown alongside bedrooms, so it's visible why a search matched.
- The reference-design header star toggles the favourites filter. Hearts on individual cards still save and remove properties; there is no separate saved-search action.

## Settings

Refactored in UIKit, keeping the existing `SettingsView` wrapper (`UIViewControllerRepresentable`). The screen has no data or business rules, so it needs no use cases or repositories. One row model and a thin controller are enough.

- **One source of truth, open for new rows.** Before, the layout was written three times, as nested `if`s, in the row counts, the cell setup and the tap handling; those copies could drift apart silently, showing a blank cell or running another row's action. Now each `SettingsRow` carries its title, icon, value and action, and `makeSections()` lists them in order. The table methods only read rows and call `row.action()` when one is tapped, so adding, removing or reordering a row is one entry in `makeSections()` and the table code never changes. The menu lives in the controller because its actions call the supplied private placeholders.
- **Current UIKit APIs.** Cells use `UIListContentConfiguration.valueCell()` and are reused. That replaces:
  - five copy-pasted cell setups
  - `textLabel`, `detailTextLabel` and `imageView`, which are slated for deprecation
  - a registered cell identifier that was never dequeued

  Setup no longer lives in `loadView()`, and the lines that only restated defaults are gone.
- **No custom initializers.** The wrapper creates the controller with UIKit's own `init(style: .insetGrouped)` and embeds it in a navigation controller with large titles; the controller sets its "My Account" title in `viewDidLoad`.
- **Two fixes:**
  - **Dark mode:** cells no longer override their background. The override made the cards invisible in dark mode.
  - **Language:** the app is English-only; the row displays "English" directly, without reading bundle preferences or translating a language name.
- **Unchanged:** the rows, their order, the country placeholder, and the five placeholder actions marked "NO NEED TO TOUCH", which still print their names, byte-for-byte as supplied.

Simple XCTest checks cover the title, section and row counts, row content and icons, and deselection on tap. Settings follows the shared formatting rules too.

## Tests

The shared Tahudu scheme uses `TestPlans/Tahudu.xctestplan` for the app and package test bundles.

Tests cover:

- the listings data layer (data source and repository together, with only HTTP stubbed): endpoint, mapping, rejecting malformed responses, validating IDs, error mapping, private failure logs
- search, filter and sort rules
- favourites persistence
- the view model: loading, retry, awaited refreshes, cancellation and view re-entry, non-blocking refresh feedback, logging, favourites and filters
- card text: prices, areas, dates and room counts
- endpoint request building (shared base URL, method, JSON `Accept`, extra headers) and JSON decoding in the client
- that log messages are private unless marked public
- the app coordinator
- the Settings screen with XCTest: title, section and row counts, row text and values, icons and disclosure indicators, and deselection on tap

## Next steps


- Snapshot tests for the card and header.
- Real contact actions (`tel:`, `mailto:`, WhatsApp).
- Remote images with caching once the API serves photo URLs.
- A shared favourites store if another feature needs to edit favourites.

# Solution notes

## Running it

Open `Tahudu.xcodeproj` in Xcode 26 or newer, select **Tahudu** and an iOS 26 simulator, then run. The project, shared scheme and root test plan are included. No third-party app libraries or setup scripts are required. Choose your own development team to run on a physical device.

## Current scope

The SwiftUI Listings screen renders the supplied API feed. Property cards show tags, delivery year, price, location, bedrooms (including Studio), bathrooms, area, contact options, photo paging, publication dates and an optional last-contacted banner. The pinned header stays above the scrolling results.

At this stage the header controls and card hearts log taps; favourites, text search, filters and sorting will be wired in the next commits. Contact actions remain logging placeholders. Settings keeps the supplied UIKit implementation without refactoring.

Initial loading and retry show one progress indicator outside the refreshable list. Once loaded, results and the empty-feed state use a native List with pull-to-refresh. Refresh awaits the fetch, keeps existing cards interactive and reports failures inline. Cancellation is not displayed as an error.

## Architecture

```text
Tahudu
├── AppFactory: constructs shared services and feature factories
├── AppCoordinator: tab selection and screen composition
└── TahuduTabView
Packages/PropertyFinderKit
├── Features/Listings
│   ├── Domain: Listing, errors, repository contract and fetch use case
│   ├── Data: endpoint, DTO, remote data source and repository
│   └── Presentation: observable view model, view state, display models and views
├── DesignSystem: semantic colours, font roles, spacing, input and shared assets
├── Networking: endpoint/request construction, HTTP validation and JSON decoding
├── Logger: unified logging through an injected protocol
└── Extensions: small shared Foundation and SwiftUI helpers
```

Each feature owns its layers rather than sharing horizontal feature-wide layers. The view owns its model in State and talks to its protocol. The view model depends on a fetch-use-case protocol; the use case depends on a Domain repository contract. The Data implementation maps DTOs and transport errors to Domain values. Factories compose these dependencies without a container or singleton service locator.

Only feature factories/screens and required shared service contracts are public. Shared APIs needed only inside the Swift package use package access. Conformances with implementations live in same-file extensions, except where presentation-owned error messages deliberately extend a Domain error in the presentation layer.

## Decisions

- **Observation:** SwiftUI observes the properties read by a body. The view model uses Observation, and one standalone ListingsViewState represents loading, failure, an empty feed or display-ready cards. Components separate the header, list, cards and photos.
- **Concurrency:** Swift 6 language mode with complete checking. The UI-only app defaults to MainActor; package targets stay nonisolated by default and UI state is explicitly MainActor-isolated. Cross-isolation listing values and network contracts are Sendable.
- **Decoding:** synthesized Decodable reads the normal listings envelope. Invalid required fields/dates reject the response. The repository drops blank identifiers and keeps the first duplicate ID to preserve list identity.
- **Errors:** Domain owns ListingsError. Data maps network/decoding errors; Presentation supplies explicit English messages. Refresh failures retain the previous content and do not present a blocking alert.
- **Caching:** the injected URLSession uses its default configuration and HTTP cache policy. The supplied feed exposes an ETag with `Cache-Control: public, max-age=0, must-revalidate`; the system can validate and reuse an unchanged cached body. No manual 304 handling, custom expiry or arbitrary cache capacity is added.
- **Timeouts:** URLSession defaults are retained; the task provides no measured basis for custom values.
- **Pagination:** repeated probes of page/limit, offset, cursor and range formats returned the same 42 listings without paging metadata. No supported server pagination was found. The app keeps the small complete feed and renders rows lazily.
- **Presentation:** the interface is English and left-to-right. Card number/date formatting uses an explicit English locale. Dynamic Type, accessible labels and minimum 44pt control targets are included.
- **Design:** semantic font roles match the brief's caption2 tags, headline price and caption details. Spacing tokens provide shared multiples of four. Control dimensions and corner radii retain their layout meanings.
- **Photos:** zero images show a placeholder; one renders a static photo; multiple images create a carousel with paging and VoiceOver adjustment. Unknown image names show a placeholder. Both supplied API names and catalog names are accepted.
- **Assets:** shared colours, symbols and photos live in the DesignSystem catalog. The app catalog retains the app icon. Photos include downsampled 1×/2× renditions and the original 3× image.
- **Logging:** debug/info/error use unified-log levels. Complete messages are private by default, while fixed non-sensitive tap messages can opt into public visibility. Private values can still be visible while debugging.
- **Previews:** Debug-only listing and view-model fixtures keep repository construction out of view files.

## Verification

The shared scheme uses `TestPlans/Tahudu.xctestplan`. Tests cover endpoint construction/decoding, data-source and repository integration, invalid feed handling, error mapping, log privacy, display formatting, view-model loading/retry/refresh/cancellation and app coordination.

The supplied Settings controller is unchanged in this commit. Its bonus refactor and tests will be isolated in their own commit. Snapshot coverage and real contact actions remain future work.

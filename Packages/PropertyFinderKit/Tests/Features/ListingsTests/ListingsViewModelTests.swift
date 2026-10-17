import Foundation
@testable import Listings
import Logger
import Testing

@MainActor
struct ListingsViewModelTests {
    private let feed: [Listing] = [
        .mock(id: "marina", location: "Dubai Marina"),
        .mock(id: "studio", location: "Jumeirah Lake Towers", bedrooms: nil),
        .mock(id: "villa", type: "Villa", location: "Arabian Ranches", bedrooms: 4),
    ]

    // MARK: Loading

    @Test func showsCardsAfterLoading() async {
        let model = makeModel(fetch: SequencedFetchListings([.success(feed)]), favourites: ["studio"])
        #expect(model.state == .loading)

        await model.load()

        #expect(model.cards.map(\.id) == ["marina", "studio", "villa"])
        #expect(model.cards.map(\.isFavourite) == [false, true, false])
    }

    @Test func loadingAgainAfterAFailureRetries() async {
        let model = makeModel(fetch: SequencedFetchListings([.failure(.connection), .success(feed)]))
        await model.load()
        #expect(model.state == .failed(.connection))

        await model.load()

        #expect(model.cards.count == 3)
    }

    @Test func retryingShowsLoadingUntilTheNewRequestFinishes() async throws {
        let fetch = ControlledFetchListings()
        let model = makeModel(fetch: fetch)
        let first = Task { await model.load() }
        try await waitUntil { fetch.callCount == 1 }
        fetch.complete(call: 0, with: .failure(ListingsError.connection))
        await first.value

        let retry = Task { await model.load() }
        try await waitUntil { fetch.callCount == 2 }
        #expect(model.state == .loading)

        fetch.complete(call: 1, with: .success(feed))
        await retry.value
        #expect(model.cards.count == 3)
    }

    @Test func doesNotReloadOnceLoaded() async throws {
        let fetch = ControlledFetchListings()
        let model = makeModel(fetch: fetch)
        let load = Task { await model.load() }
        try await waitUntil { fetch.callCount == 1 }
        fetch.complete(call: 0, with: .success(feed))
        await load.value

        await model.load()

        #expect(fetch.callCount == 1)
    }

    @Test func aNewViewLoadCanFinishBeforeACancelledLoadReturns() async throws {
        let fetch = ControlledFetchListings()
        let model = makeModel(fetch: fetch)
        let oldLoad = Task { await model.load() }
        try await waitUntil { fetch.callCount == 1 }
        oldLoad.cancel()

        let newLoad = Task { await model.load() }
        try await waitUntil { fetch.callCount == 2 }
        fetch.complete(call: 1, with: .success([.mock(id: "current")]))
        await newLoad.value
        #expect(model.cards.map(\.id) == ["current"])

        fetch.complete(call: 0, with: .success([.mock(id: "cancelled")]))
        await oldLoad.value
        #expect(model.cards.map(\.id) == ["current"])
    }

    @Test func cancellationLeavesTheModelReadyToLoadAgain() async throws {
        let fetch = ControlledFetchListings()
        let model = makeModel(fetch: fetch)

        let load = Task { await model.load() }
        try await waitUntil { fetch.callCount == 1 }
        load.cancel()
        fetch.complete(call: 0, with: .failure(CancellationError()))
        await load.value
        #expect(model.state == .loading, "Cancellation is not shown as an error")

        let reload = Task { await model.load() }
        try await waitUntil { fetch.callCount == 2 }
        fetch.complete(call: 1, with: .success(feed))
        await reload.value
        #expect(model.cards.count == 3)
    }

    @Test func aFailedRefreshKeepsTheCurrentListings() async {
        let model = makeModel(fetch: SequencedFetchListings([.success(feed), .failure(.timedOut)]))
        await model.load()

        await model.refresh()

        #expect(model.cards.count == 3)
        #expect(model.refreshMessage != nil)
    }

    @Test func aSuccessfulRefreshReplacesTheListings() async {
        let model = makeModel(fetch: SequencedFetchListings([.success(feed), .success([.mock(id: "new")])]))
        await model.load()

        await model.refresh()

        #expect(model.cards.map(\.id) == ["new"])
    }

    @Test func anEmptyFeedCanBeRefreshed() async {
        let model = makeModel(fetch: SequencedFetchListings([.success([]), .success(feed)]))
        await model.load()
        #expect(model.state == .noListings)

        await model.refresh()

        #expect(model.cards.count == 3)
        #expect(model.refreshMessage == nil)
    }

    @Test func aSuccessfulRefreshClearsAnEarlierRefreshMessage() async {
        let model = makeModel(fetch: SequencedFetchListings([.success(feed), .failure(.timedOut), .success(feed)]))
        await model.load()
        await model.refresh()
        #expect(model.refreshMessage != nil)

        await model.refresh()

        #expect(model.refreshMessage == nil)
        #expect(model.cards.count == 3)
    }

    @Test func refreshWaitsForItsResponseAndKeepsExistingCardsWhilePending() async throws {
        let fetch = ControlledFetchListings()
        let model = makeModel(fetch: fetch)
        let load = Task { await model.load() }
        try await waitUntil { fetch.callCount == 1 }
        fetch.complete(call: 0, with: .success(feed))
        await load.value

        var refreshFinished = false
        let refresh = Task {
            await model.refresh()
            refreshFinished = true
        }
        try await waitUntil { fetch.callCount == 2 }
        #expect(!refreshFinished)
        #expect(model.cards.count == 3)

        fetch.complete(call: 1, with: .success([.mock(id: "refreshed")]))
        await refresh.value

        #expect(refreshFinished)
        #expect(model.cards.map(\.id) == ["refreshed"])
    }

    @Test func cancellingARefreshDiscardsEvenASuccessfulResponse() async throws {
        let fetch = ControlledFetchListings()
        let model = makeModel(fetch: fetch)
        let load = Task { await model.load() }
        try await waitUntil { fetch.callCount == 1 }
        fetch.complete(call: 0, with: .success(feed))
        await load.value

        let refresh = Task { await model.refresh() }
        try await waitUntil { fetch.callCount == 2 }
        refresh.cancel()
        fetch.complete(call: 1, with: .success([.mock(id: "cancelled")]))
        await refresh.value

        #expect(model.cards.map(\.id) == ["marina", "studio", "villa"])
        #expect(model.refreshMessage == nil)
    }

    @Test func refreshIsIgnoredUntilTheInitialLoadSucceeds() async throws {
        let fetch = ControlledFetchListings()
        let model = makeModel(fetch: fetch)
        let load = Task { await model.load() }
        try await waitUntil { fetch.callCount == 1 }

        await model.refresh()
        #expect(fetch.callCount == 1)
        #expect(model.state == .loading)

        fetch.complete(call: 0, with: .failure(ListingsError.connection))
        await load.value
        await model.refresh()
        #expect(fetch.callCount == 1)
        #expect(model.state == .failed(.connection))
    }

    @Test func contactActionUsesTheInjectedLogger() {
        let logger = SpyLogger()
        let model = makeModel(fetch: SequencedFetchListings([]), logger: logger)

        model.contact(.phone, listingID: "private-listing-id")

        #expect(logger.loggedEntries.map(\.message) == ["Contact phone for private-listing-id"])
        #expect(logger.loggedEntries.map(\.privacy) == [.private])
    }

    // MARK: State

    @Test func showsTheResultsAsCards() async {
        let model = makeModel(fetch: SequencedFetchListings([.success(feed)]))
        #expect(model.state == .loading)

        await model.load()

        #expect(model.state == .results(feed.map { ListingCardViewData(listing: $0, isFavourite: false) }))
    }

    @Test func distinguishesAnEmptyFeed() async {
        let model = makeModel(fetch: SequencedFetchListings([.success([])]))

        await model.load()

        #expect(model.state == .noListings)
    }

    @Test func showsNoFavouritesUntilAPropertyIsSaved() async {
        let model = makeModel(fetch: SequencedFetchListings([.success(feed)]))
        await model.load()

        model.criteria.favouritesOnly = true
        #expect(model.state == .noFavourites, "Nothing has been saved yet")

        model.toggleFavourite(id: "villa")
        #expect(model.cards.map(\.id) == ["villa"])

        model.toggleFavourite(id: "villa")
        #expect(model.state == .noFavourites, "Removing the last favourite empties the favourites view")
    }

    // MARK: Favourites

    @Test func togglingAFavouriteUpdatesTheCardAndPersists() async {
        let repository = InMemoryFavouritesRepository()
        let model = makeModel(fetch: SequencedFetchListings([.success(feed)]), repository: repository)
        await model.load()

        model.toggleFavourite(id: "villa")
        #expect(model.cards.first { $0.id == "villa" }?.isFavourite == true)
        #expect(repository.ids == ["villa"])

        model.toggleFavourite(id: "villa")
        #expect(model.cards.first { $0.id == "villa" }?.isFavourite == false)
        #expect(repository.ids.isEmpty)
    }

    @Test func favouritesFilterShowsOnlySavedListings() async {
        let model = makeModel(fetch: SequencedFetchListings([.success(feed)]), favourites: ["villa", "marina"])
        await model.load()
        #expect(model.resultsSummary == nil)

        model.criteria.favouritesOnly = true
        #expect(model.cards.map(\.id) == ["marina", "villa"])
        #expect(model.resultsSummary == "2 saved properties")

        model.toggleFavourite(id: "marina")
        #expect(model.cards.map(\.id) == ["villa"], "Unfavouriting removes the card from the favourites view")
        #expect(model.resultsSummary == "1 saved property")

        model.criteria.favouritesOnly = false
        #expect(model.cards.count == 3)
        #expect(model.resultsSummary == nil)
    }

    // MARK: Helpers

    private func makeModel(
        fetch: any FetchListingsUseCaseProtocol,
        favourites: Set<String> = [],
        repository: InMemoryFavouritesRepository? = nil,
        logger: SpyLogger = SpyLogger()
    ) -> ListingsViewModel {
        let repository = repository ?? InMemoryFavouritesRepository(ids: favourites)
        return ListingsViewModel(
            fetchListingsUseCase: fetch,
            loadFavouritesUseCase: LoadFavouritesUseCase(repository: repository),
            toggleFavouriteUseCase: ToggleFavouriteUseCase(repository: repository),
            queryListingsUseCase: QueryListingsUseCase(),
            logger: logger
        )
    }
}

private extension ListingsViewModel {
    /// The cards on screen, or none while the screen shows a message instead.
    var cards: [ListingCardViewData] {
        guard case let .results(cards) = state else { return [] }
        return cards
    }
}

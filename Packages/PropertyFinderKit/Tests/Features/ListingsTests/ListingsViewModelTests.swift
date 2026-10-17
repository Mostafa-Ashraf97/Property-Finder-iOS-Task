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
        let model = makeModel(fetch: SequencedFetchListings([.success(feed)]))
        #expect(model.state == .loading)

        await model.load()

        #expect(model.cards.map(\.id) == ["marina", "studio", "villa"])
        #expect(model.cards.map(\.isFavourite) == [false, false, false])
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

    // MARK: Helpers

    private func makeModel(
        fetch: any FetchListingsUseCaseProtocol,
        logger: SpyLogger = SpyLogger()
    ) -> ListingsViewModel {
        ListingsViewModel(
            fetchListingsUseCase: fetch,
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

import Foundation
@testable import Listings
import XCTest

@MainActor
final class ListingsViewModelTests: XCTestCase {
    private let listings: [Listing] = [
        .fixture(id: "a", type: "Apartment", location: "Dubai Marina"),
        .fixture(id: "b", type: "Villa", location: "Palm Jumeirah"),
    ]

    func test_load_whenTheFetchSucceeds_showsTheResults() async {
        // Given
        let (viewModel, _) = makeListingsViewModel(feeds: [.success(.fresh(listings))])

        // When
        await viewModel.load()

        // Then
        XCTAssertEqual(viewModel.cardIDs, ["a", "b"])
    }

    func test_load_whenTheFetchFails_showsTheError() async {
        // Given
        let (viewModel, _) = makeListingsViewModel(feeds: [.failure(.connection)])

        // When
        await viewModel.load()

        // Then
        XCTAssertEqual(viewModel.state, .failed(.connection))
    }

    func test_load_whenTheFeedIsEmpty_showsNoListings() async {
        // Given
        let (viewModel, _) = makeListingsViewModel(feeds: [.success(.fresh([]))])

        // When
        await viewModel.load()

        // Then
        XCTAssertEqual(viewModel.state, .noListings)
    }

    func test_load_whenAlreadyLoaded_doesNotFetchAgain() async {
        // Given
        let (viewModel, fetch) = makeListingsViewModel(feeds: [.success(.fresh(listings))])
        await viewModel.load()

        // When
        await viewModel.load()

        // Then
        XCTAssertEqual(fetch.callCount, 1)
    }

    func test_criteria_withTheFavouritesFilterAndNothingSaved_showsNoFavourites() async {
        // Given
        let (viewModel, _) = makeListingsViewModel(feeds: [.success(.fresh(listings))])
        await viewModel.load()

        // When
        viewModel.criteria.favouritesOnly = true

        // Then
        XCTAssertEqual(viewModel.state, .noFavourites)
    }

    func test_criteria_withASearchThatMatchesNothing_showsNoMatches() async {
        // Given
        let (viewModel, _) = makeListingsViewModel(feeds: [.success(.fresh(listings))])
        await viewModel.load()

        // When
        viewModel.criteria.text = "nowhere"

        // Then
        XCTAssertEqual(viewModel.state, .noMatches)
    }

    func test_resultsSummary_whenASearchNarrowsTheResults_countsShownOfTotal() async {
        // Given
        let (viewModel, _) = makeListingsViewModel(feeds: [.success(.fresh(listings))])
        await viewModel.load()

        // When
        viewModel.criteria.text = "marina"

        // Then
        XCTAssertEqual(viewModel.resultsSummary, "1 of 2 properties")
    }

    func test_resultsSummary_withTheFavouritesFilter_countsSavedProperties() async {
        // Given
        let (viewModel, _) = makeListingsViewModel(feeds: [.success(.fresh(listings))], favourites: ["a"])
        await viewModel.load()

        // When
        viewModel.criteria.favouritesOnly = true

        // Then
        XCTAssertEqual(viewModel.resultsSummary, "1 saved property")
    }

    func test_matchingCount_previewsFiltersWithoutApplyingThem() async {
        // Given
        let (viewModel, _) = makeListingsViewModel(feeds: [.success(.fresh(listings))])
        await viewModel.load()

        // When
        let count = viewModel.matchingCount(for: ListingFilters(propertyTypes: ["Villa"]))

        // Then
        XCTAssertEqual(count, 1)
        XCTAssertEqual(viewModel.cardIDs, ["a", "b"])
    }

    func test_clearSearchAndFilters_keepsTheFavouritesFilterAndSortOrder() {
        // Given
        let (viewModel, _) = makeListingsViewModel(feeds: [])
        viewModel.criteria = ListingSearchCriteria(
            text: "marina",
            filters: ListingFilters(propertyTypes: ["Villa"]),
            sortOrder: .newest,
            favouritesOnly: true
        )

        // When
        viewModel.clearSearchAndFilters()

        // Then
        XCTAssertEqual(viewModel.criteria, ListingSearchCriteria(sortOrder: .newest, favouritesOnly: true))
    }

    func test_refresh_whenTheFetchFails_keepsTheResultsAndShowsAMessage() async {
        // Given
        let (viewModel, _) = makeListingsViewModel(feeds: [.success(.fresh(listings)), .failure(.connection)])
        await viewModel.load()

        // When
        await viewModel.refresh()

        // Then
        XCTAssertEqual(viewModel.cardIDs, ["a", "b"])
        XCTAssertNotNil(viewModel.refreshMessage)
    }

    func test_refresh_beforeTheFirstLoad_doesNothing() async {
        // Given
        let (viewModel, fetch) = makeListingsViewModel(feeds: [])

        // When
        await viewModel.refresh()

        // Then
        XCTAssertEqual(fetch.callCount, 0)
        XCTAssertEqual(viewModel.state, .loading)
    }

    func test_load_whenTheFeedIsSaved_showsTheSavedListingsNotice() async {
        // Given
        let (viewModel, _) = makeListingsViewModel(feeds: [.success(.saved(listings))])

        // When
        await viewModel.load()

        // Then
        XCTAssertTrue(viewModel.isShowingSavedListings)
    }

    func test_refresh_whenTheFeedIsFresh_hidesTheSavedListingsNotice() async {
        // Given
        let (viewModel, _) = makeListingsViewModel(feeds: [.success(.saved(listings)), .success(.fresh(listings))])
        await viewModel.load()

        // When
        await viewModel.refresh()

        // Then
        XCTAssertFalse(viewModel.isShowingSavedListings)
    }

    func test_observeUpdates_whenReconnectingWhileShowingSavedListings_fetchesAgain() async {
        // Given
        let network = StubNetworkMonitor()
        let (viewModel, fetch) = makeListingsViewModel(
            feeds: [.success(.saved(listings)), .success(.fresh(listings))],
            network: network
        )
        await viewModel.load()
        network.reconnect()

        // When
        await viewModel.observeUpdates()

        // Then
        XCTAssertEqual(fetch.callCount, 2)
        XCTAssertFalse(viewModel.isShowingSavedListings)
    }

    func test_observeUpdates_whenReconnectingAfterAFailedLoad_loadsAgain() async {
        // Given
        let network = StubNetworkMonitor()
        let (viewModel, fetch) = makeListingsViewModel(
            feeds: [.failure(.connection), .success(.fresh(listings))],
            network: network
        )
        await viewModel.load()
        network.reconnect()

        // When
        await viewModel.observeUpdates()

        // Then
        XCTAssertEqual(fetch.callCount, 2)
        XCTAssertEqual(viewModel.cardIDs, ["a", "b"])
    }

    func test_observeUpdates_whenReconnectingWithCurrentListings_doesNotFetch() async {
        // Given
        let network = StubNetworkMonitor()
        let (viewModel, fetch) = makeListingsViewModel(feeds: [.success(.fresh(listings))], network: network)
        await viewModel.load()
        network.reconnect()

        // When
        await viewModel.observeUpdates()

        // Then
        XCTAssertEqual(fetch.callCount, 1)
    }

    func test_observeUpdates_whenTheFirstReportIsOnline_doesNotFetch() async {
        // Given
        let network = StubNetworkMonitor()
        let (viewModel, fetch) = makeListingsViewModel(feeds: [.success(.saved(listings))], network: network)
        await viewModel.load()
        network.send(true)
        network.finish()

        // When
        await viewModel.observeUpdates()

        // Then
        XCTAssertEqual(fetch.callCount, 1)
    }

    func test_toggleFavourite_flipsTheCardsHeart() async {
        // Given
        let (viewModel, _) = makeListingsViewModel(feeds: [.success(.fresh(listings))])
        await viewModel.load()

        // When
        viewModel.toggleFavourite(id: "a")

        // Then
        XCTAssertEqual(viewModel.cards.first { $0.id == "a" }?.isFavourite, true)
    }

    func test_contact_logsTheListingIDOnlyAsPrivateDetails() {
        // Given
        let logger = SpyLogger()
        let (viewModel, _) = makeListingsViewModel(feeds: [], logger: logger)

        // When
        viewModel.contact(.phone, listingID: "prop_001")

        // Then
        XCTAssertEqual(logger.loggedEntries, [SpyLogger.Entry(message: "Contact phone", details: "prop_001")])
    }

    func test_featureFlags_withOnlyFiltersEnabled_enableFiltersButNotSorting() {
        // Given
        let flags = StubFeatureFlags(enabled: [.listingsFiltersEnabled])

        // When
        let (viewModel, _) = makeListingsViewModel(feeds: [], flags: flags)

        // Then
        XCTAssertTrue(viewModel.isFilterEnabled)
        XCTAssertFalse(viewModel.isSortEnabled)
    }
}

private extension ListingsViewModel {
    var cards: [ListingCardViewData] {
        guard case let .results(cards) = state else { return [] }
        return cards
    }

    var cardIDs: [String] {
        cards.map(\.id)
    }
}

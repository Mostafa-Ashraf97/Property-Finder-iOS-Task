import Foundation
@testable import Listings
import Testing

struct QueryListingsUseCaseTests {
    private let useCase = QueryListingsUseCase()
    private let listings: [Listing] = [
        .mock(
            id: "marina",
            price: 1_850_000,
            location: "Marina Heights, Dubai Marina",
            bedrooms: 1,
            publishedAt: .init(timeIntervalSince1970: 300)
        ),
        .mock(
            id: "studio",
            price: 2_575_000,
            location: "Laguna Tower, Jumeirah Lake Towers",
            bedrooms: nil,
            publishedAt: .init(timeIntervalSince1970: 100)
        ),
        .mock(
            id: "villa",
            type: "Villa",
            price: 7_900_000,
            location: "Arabian Ranches, Dubai",
            bedrooms: 4,
            publishedAt: .init(timeIntervalSince1970: 200)
        ),
        .mock(
            id: "palm",
            price: 1_850_000,
            location: "Shoreline, Palm Jumeirah",
            bedrooms: 1,
            publishedAt: .init(timeIntervalSince1970: 300)
        ),
    ]

    @Test func returnsEverythingInFeedOrderByDefault() {
        #expect(ids(ListingSearchCriteria()) == ["marina", "studio", "villa", "palm"])
    }

    @Test func requiresEveryWordToMatchIgnoringCaseAndDiacritics() {
        var criteria = ListingSearchCriteria()

        criteria.text = "  dubai MARINA "
        #expect(ids(criteria) == ["marina"])

        criteria.text = "jumeirah"
        #expect(ids(criteria) == ["studio", "palm"])

        criteria.text = "Jumeírah lake"
        #expect(ids(criteria) == ["studio"])
    }

    @Test func matchesThePropertyType() {
        var criteria = ListingSearchCriteria()
        criteria.text = "villa"

        #expect(ids(criteria) == ["villa"])
    }

    @Test func filtersByTypeAndBedrooms() {
        var criteria = ListingSearchCriteria()

        criteria.filters.propertyTypes = ["Apartment"]
        #expect(ids(criteria) == ["marina", "studio", "palm"])

        criteria.filters.bedrooms = .studio
        #expect(ids(criteria) == ["studio"])

        criteria.filters.propertyTypes = []
        criteria.filters.bedrooms = .count(4)
        #expect(ids(criteria) == ["villa"])
    }

    @Test func limitsResultsToFavouritesWhenRequested() {
        var criteria = ListingSearchCriteria()
        criteria.favouritesOnly = true

        #expect(ids(criteria, favourites: ["villa", "palm", "not-in-feed"]) == ["villa", "palm"])
        #expect(ids(criteria, favourites: []).isEmpty)
    }

    @Test func sortsNewestFirstKeepingFeedOrderForTies() {
        var criteria = ListingSearchCriteria()
        criteria.sortOrder = .newest

        #expect(ids(criteria) == ["marina", "palm", "villa", "studio"])
    }

    @Test func sortsByPriceInBothDirectionsKeepingFeedOrderForTies() {
        var criteria = ListingSearchCriteria()

        criteria.sortOrder = .priceLowToHigh
        #expect(ids(criteria) == ["marina", "palm", "studio", "villa"])

        criteria.sortOrder = .priceHighToLow
        #expect(ids(criteria) == ["villa", "studio", "marina", "palm"])
    }

    @Test func groupsCurrenciesBeforeSortingTheirAmounts() {
        let mixedCurrencies: [Listing] = [
            .mock(id: "usd_low", price: 1, currency: "USD"),
            .mock(id: "aed_high", price: 3, currency: "AED"),
            .mock(id: "aed_low", price: 1, currency: "AED"),
            .mock(id: "usd_high", price: 3, currency: "USD"),
        ]
        var criteria = ListingSearchCriteria()

        criteria.sortOrder = .priceLowToHigh
        let ascending = useCase.execute(listings: mixedCurrencies, criteria: criteria, favouriteIDs: [])
        #expect(ascending.map(\.id) == ["aed_low", "aed_high", "usd_low", "usd_high"])

        criteria.sortOrder = .priceHighToLow
        let descending = useCase.execute(listings: mixedCurrencies, criteria: criteria, favouriteIDs: [])
        #expect(descending.map(\.id) == ["aed_high", "aed_low", "usd_high", "usd_low"])
    }

    private func ids(_ criteria: ListingSearchCriteria, favourites: Set<String> = []) -> [String] {
        useCase.execute(listings: listings, criteria: criteria, favouriteIDs: favourites).map(\.id)
    }
}

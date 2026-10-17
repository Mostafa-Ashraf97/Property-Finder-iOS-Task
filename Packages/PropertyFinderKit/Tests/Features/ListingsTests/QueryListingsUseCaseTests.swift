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

    @Test func limitsResultsToFavouritesWhenRequested() {
        var criteria = ListingSearchCriteria()
        criteria.favouritesOnly = true

        #expect(ids(criteria, favourites: ["villa", "palm", "not-in-feed"]) == ["villa", "palm"])
        #expect(ids(criteria, favourites: []).isEmpty)
    }

    private func ids(_ criteria: ListingSearchCriteria, favourites: Set<String> = []) -> [String] {
        useCase.execute(listings: listings, criteria: criteria, favouriteIDs: favourites).map(\.id)
    }
}

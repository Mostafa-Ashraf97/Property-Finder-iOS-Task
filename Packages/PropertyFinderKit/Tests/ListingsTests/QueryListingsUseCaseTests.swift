import Foundation
@testable import Listings
import XCTest

final class QueryListingsUseCaseTests: XCTestCase {
    private let listings: [Listing] = [
        .fixture(
            id: "marina",
            price: 1_850_000,
            location: "Marina Heights, Dubai Marina",
            bedrooms: 1,
            publishedAt: Date(timeIntervalSince1970: 300)
        ),
        .fixture(
            id: "studio",
            price: 2_575_000,
            location: "Laguna Tower, Jumeirah Lake Towers",
            bedrooms: nil,
            publishedAt: Date(timeIntervalSince1970: 100)
        ),
        .fixture(
            id: "villa",
            type: "Villa",
            price: 7_900_000,
            location: "Arabian Ranches, Dubai",
            bedrooms: 4,
            publishedAt: Date(timeIntervalSince1970: 200)
        ),
        .fixture(
            id: "palm",
            price: 1_850_000,
            location: "Shoreline, Palm Jumeirah",
            bedrooms: 1,
            publishedAt: Date(timeIntervalSince1970: 300)
        ),
    ]

    func test_execute_withDefaultCriteria_keepsTheFeedOrder() {
        // When
        let result = ids(ListingSearchCriteria())

        // Then
        XCTAssertEqual(result, ["marina", "studio", "villa", "palm"])
    }

    func test_execute_withSeveralWords_requiresEveryWordToMatch() {
        // When
        let result = ids(ListingSearchCriteria(text: "jumeirah lake"))

        // Then
        XCTAssertEqual(result, ["studio"])
    }

    func test_execute_withText_ignoresCaseDiacriticsAndSpaces() {
        // When
        let result = ids(ListingSearchCriteria(text: "  JUMEÍRAH "))

        // Then
        XCTAssertEqual(result, ["studio", "palm"])
    }

    func test_execute_withText_matchesThePropertyType() {
        // When
        let result = ids(ListingSearchCriteria(text: "villa"))

        // Then
        XCTAssertEqual(result, ["villa"])
    }

    func test_execute_withAPropertyTypeFilter_keepsThatType() {
        // When
        let result = ids(ListingSearchCriteria(filters: ListingFilters(propertyTypes: ["Apartment"])))

        // Then
        XCTAssertEqual(result, ["marina", "studio", "palm"])
    }

    func test_execute_withTheStudioFilter_keepsListingsWithoutBedrooms() {
        // When
        let result = ids(ListingSearchCriteria(filters: ListingFilters(bedrooms: .studio)))

        // Then
        XCTAssertEqual(result, ["studio"])
    }

    func test_execute_withABedroomCount_keepsThatExactCount() {
        // When
        let result = ids(ListingSearchCriteria(filters: ListingFilters(bedrooms: .count(4))))

        // Then
        XCTAssertEqual(result, ["villa"])
    }

    func test_execute_withFavouritesOnly_keepsSavedListingsInTheFeed() {
        // Given
        let favourites: Set = ["villa", "palm", "not-in-feed"]

        // When
        let result = ids(ListingSearchCriteria(favouritesOnly: true), favourites: favourites)

        // Then
        XCTAssertEqual(result, ["villa", "palm"])
    }

    func test_execute_sortedByNewest_keepsFeedOrderForTies() {
        // When
        let result = ids(ListingSearchCriteria(sortOrder: .newest))

        // Then
        XCTAssertEqual(result, ["marina", "palm", "villa", "studio"])
    }

    func test_execute_sortedByPriceLowToHigh_keepsFeedOrderForTies() {
        // When
        let result = ids(ListingSearchCriteria(sortOrder: .priceLowToHigh))

        // Then
        XCTAssertEqual(result, ["marina", "palm", "studio", "villa"])
    }

    func test_execute_sortedByPriceHighToLow_keepsFeedOrderForTies() {
        // When
        let result = ids(ListingSearchCriteria(sortOrder: .priceHighToLow))

        // Then
        XCTAssertEqual(result, ["villa", "studio", "marina", "palm"])
    }

    private func ids(_ criteria: ListingSearchCriteria, favourites: Set<String> = []) -> [String] {
        QueryListingsUseCase().execute(listings: listings, criteria: criteria, favouriteIDs: favourites).map(\.id)
    }
}

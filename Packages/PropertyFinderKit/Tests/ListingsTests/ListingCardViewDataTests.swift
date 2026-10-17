import Foundation
@testable import Listings
import XCTest

final class ListingCardViewDataTests: XCTestCase {
    func test_init_formatsThePriceAndArea() {
        // Given
        let listing = Listing.fixture(price: 2_575_000, areaSqft: 1356)

        // When
        let card = ListingCardViewData(listing: listing, isFavourite: false)

        // Then
        XCTAssertEqual(card.price, "2,575,000 AED")
        XCTAssertEqual(card.area, "1,356 sqft")
    }

    func test_init_withoutBedrooms_showsStudio() {
        // When
        let card = ListingCardViewData(listing: .fixture(bedrooms: nil), isFavourite: false)

        // Then
        XCTAssertEqual(card.bedrooms, "Studio")
    }

    func test_init_withRoomCounts_usesSingularAndPlural() {
        // When
        let oneBedroom = ListingCardViewData(listing: .fixture(bedrooms: 1, bathrooms: 1), isFavourite: false)
        let twoBedrooms = ListingCardViewData(listing: .fixture(bedrooms: 2, bathrooms: 2), isFavourite: false)

        // Then
        XCTAssertEqual(oneBedroom.bedrooms, "1 Bed")
        XCTAssertEqual(oneBedroom.bathrooms, "1 Bath")
        XCTAssertEqual(twoBedrooms.bedrooms, "2 Beds")
        XCTAssertEqual(twoBedrooms.bathrooms, "2 Baths")
    }

    func test_init_withALastContactedDate_showsTheBanner() throws {
        // Given
        let listing = try Listing.fixture(lastContactedAt: date("2021-07-28T12:00:00Z"))

        // When
        let card = ListingCardViewData(listing: listing, isFavourite: false)

        // Then
        XCTAssertEqual(card.lastContacted, "Last contacted: 28 Jul 2021")
    }

    func test_init_withoutALastContactedDate_hidesTheBanner() {
        // When
        let card = ListingCardViewData(listing: .fixture(lastContactedAt: nil), isFavourite: false)

        // Then
        XCTAssertNil(card.lastContacted)
    }

    func test_init_forAFortyDayOldListing_describesThePublishDateRelatively() {
        // Given
        let fortyDaysAgo = Date.now.addingTimeInterval(-40 * 24 * 60 * 60)

        // When
        let card = ListingCardViewData(listing: .fixture(publishedAt: fortyDaysAgo), isFavourite: false)

        // Then
        XCTAssertEqual(card.published, "Published 1 month ago")
    }
}

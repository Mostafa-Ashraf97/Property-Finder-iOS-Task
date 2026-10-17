import Foundation
@testable import Listings
import Testing

struct ListingCardViewDataTests {
    @Test func formatsTheReferenceListing() {
        let listing = Listing.mock(
            deliveryYear: 2022,
            price: 2_575_000,
            bedrooms: nil,
            areaSqft: 1356,
            publishedAt: .now.addingTimeInterval(-3 * 86400),
            // Midday UTC is the same calendar day in nearly every time zone.
            lastContactedAt: date("2021-07-28T12:00:00Z")
        )

        let card = ListingCardViewData(listing: listing, isFavourite: true)

        #expect(card.isFavourite)
        #expect(card.price == "2,575,000 AED")
        #expect(card.delivery == "Delivery: 2022")
        #expect(card.bedrooms == "Studio")
        #expect(card.bathrooms == "1 Bath")
        #expect(card.area == "1,356 sqft")
        #expect(card.published == "Published 3 days ago")
        #expect(card.lastContacted == "Last contacted: 28 Jul 2021")
    }

    @Test(arguments: [(1, "1 Bed", "1 Bath"), (3, "3 Beds", "3 Baths")])
    func pluralisesRoomCounts(count: Int, bedrooms: String, bathrooms: String) {
        let card = ListingCardViewData(listing: .mock(bedrooms: count, bathrooms: count), isFavourite: false)

        #expect(card.bedrooms == bedrooms)
        #expect(card.bathrooms == bathrooms)
        #expect(card.lastContacted == nil)
    }
}

import Foundation
@testable import Listings

extension Listing {
    static func fixture(
        id: String = "prop_001",
        type: String = "Apartment",
        price: Int = 1_000_000,
        location: String = "Dubai Marina",
        bedrooms: Int? = 1,
        bathrooms: Int = 1,
        areaSqft: Int = 900,
        publishedAt: Date = Date(timeIntervalSince1970: 1_700_000_000),
        lastContactedAt: Date? = nil
    ) -> Listing {
        Listing(
            id: id,
            type: type,
            deliveryYear: 2024,
            price: price,
            currency: "AED",
            priceInclusive: true,
            location: location,
            bedrooms: bedrooms,
            bathrooms: bathrooms,
            areaSqft: areaSqft,
            publishedAt: publishedAt,
            lastContactedAt: lastContactedAt,
            tags: [.verified],
            images: [],
            contactOptions: [.phone]
        )
    }
}

extension ListingsFeed {
    static func fresh(_ listings: [Listing]) -> ListingsFeed {
        ListingsFeed(listings: listings, isStale: false)
    }

    static func saved(_ listings: [Listing]) -> ListingsFeed {
        ListingsFeed(listings: listings, isStale: true)
    }
}

/// One listing in the API's documented JSON shape, with optional field overrides.
func listingJSON(id: String, price: Int = 2_575_000, overrides: [String: Any] = [:]) -> [String: Any] {
    var listing: [String: Any] = [
        "id": id,
        "type": "Apartment",
        "deliveryYear": 2022,
        "price": price,
        "currency": "AED",
        "priceInclusive": true,
        "location": "Laguna Tower, Jumeirah Lake Towers",
        "bedrooms": NSNull(),
        "bathrooms": 1,
        "areaSqft": 1356,
        "publishedAt": "2024-11-28T12:00:00Z",
        "lastContactedAt": NSNull(),
        "tags": ["verified"],
        "images": ["first_image"],
        "contactOptions": ["phone"],
    ]
    listing.merge(overrides) { $1 }
    return listing
}

func listingsBody(_ listings: [[String: Any]]) throws -> Data {
    try JSONSerialization.data(withJSONObject: ["listings": listings])
}

/// An ISO 8601 date. Fixtures use noon UTC, so no time zone moves them to another day.
func date(_ iso8601: String) throws -> Date {
    try Date(iso8601, strategy: .iso8601)
}

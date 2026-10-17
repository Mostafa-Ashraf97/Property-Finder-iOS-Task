@testable import Listings
import SwiftUI
import XCTest

@MainActor
final class ListingsSnapshotTests: XCTestCase {
    func test_listingCard_withPhotoTagsAndBanner_matchesSnapshot() throws {
        // Given
        let card = ListingCard(card: .detailed, onToggleFavourite: {}, onContact: { _ in })

        // When / Then
        try assertSnapshot(of: card, named: "card-detailed")
    }

    func test_listingCard_withoutPhotoTagsOrBanner_matchesSnapshot() throws {
        // Given
        let card = ListingCard(card: .minimal, onToggleFavourite: {}, onContact: { _ in })

        // When / Then
        try assertSnapshot(of: card, named: "card-minimal")
    }

    func test_listingsView_withResults_matchesSnapshot() throws {
        // Given
        let screen = UIHostingController(rootView: ListingsView(viewModel: ListingsViewModelMock())
            .environment(\.locale, Locale(identifier: "en_AE")))

        // When / Then
        try assertSnapshot(of: screen, named: "screen")
    }
}

private extension ListingCardViewData {
    static let detailed = ListingCardViewData(
        id: "detailed",
        images: ["first_image"],
        tags: [.verified, .newConstruction, .liveViewing],
        isFavourite: false,
        propertyType: "Apartment",
        delivery: "Delivery: 2022",
        price: "2,575,000 AED",
        location: "Laguna Tower, Lake Almas West, Jumeirah Lake Tower",
        bedrooms: "Studio",
        bathrooms: "1 Bath",
        area: "1,356 sqft",
        published: "Published 2 years ago",
        lastContacted: "Last contacted: 28 Jul 2021",
        contactOptions: [.phone, .email, .whatsApp]
    )

    static let minimal = ListingCardViewData(
        id: "minimal",
        images: [],
        tags: [],
        isFavourite: true,
        propertyType: "Villa",
        delivery: "Delivery: 2025",
        price: "7,900,000 AED",
        location: "Arabian Ranches, Dubai",
        bedrooms: "4 Beds",
        bathrooms: "5 Baths",
        area: "4,200 sqft",
        published: "Published 3 days ago",
        lastContacted: nil,
        contactOptions: [.email]
    )
}

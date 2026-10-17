import Extensions
import Foundation

struct ListingCardViewData: Identifiable, Equatable {
    let id: String
    let images: [String]
    let tags: [ListingTag]
    let isFavourite: Bool
    let propertyType: String
    let delivery: String
    let price: String
    let location: String
    let bedrooms: String
    let bathrooms: String
    let area: String
    let published: String
    let lastContacted: String?
    let contactOptions: [ContactType]
}

extension ListingCardViewData {
    /// Keep date and number output English regardless of the device language.
    private static let locale = Locale(identifier: "en_AE")

    init(listing: Listing, isFavourite: Bool) {
        let locale = Self.locale
        self.init(
            id: listing.id,
            images: listing.images,
            tags: listing.tags,
            isFavourite: isFavourite,
            propertyType: listing.type,
            delivery: "Delivery: \(listing.deliveryYear)",
            price: "\(listing.price.formatted(.number.locale(locale))) \(listing.currency)",
            location: listing.location,
            bedrooms: listing.bedrooms.map { $0.counted("Bed", plural: "Beds") } ?? "Studio",
            bathrooms: listing.bathrooms.counted("Bath", plural: "Baths"),
            area: "\(listing.areaSqft.formatted(.number.locale(locale))) sqft",
            published: "Published \(listing.publishedAt.formatted(.relative(presentation: .numeric).locale(locale)))",
            lastContacted: listing.lastContactedAt.map { date in
                "Last contacted: \(date.formatted(.dateTime.day(.twoDigits).month(.abbreviated).year().locale(locale)))"
            },
            contactOptions: listing.contactOptions
        )
    }
}

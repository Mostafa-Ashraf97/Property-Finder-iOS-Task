import Foundation

struct Listing: Identifiable, Equatable, Sendable {
    let id: String
    let type: String
    let deliveryYear: Int
    let price: Int
    let currency: String
    let priceInclusive: Bool
    let location: String
    let bedrooms: Int?
    let bathrooms: Int
    let areaSqft: Int
    let publishedAt: Date
    let lastContactedAt: Date?
    let tags: [ListingTag]
    let images: [String]
    let contactOptions: [ContactType]

    init(
        id: String,
        type: String,
        deliveryYear: Int,
        price: Int,
        currency: String,
        priceInclusive: Bool,
        location: String,
        bedrooms: Int?,
        bathrooms: Int,
        areaSqft: Int,
        publishedAt: Date,
        lastContactedAt: Date?,
        tags: [ListingTag],
        images: [String],
        contactOptions: [ContactType]
    ) {
        self.id = id
        self.type = type
        self.deliveryYear = deliveryYear
        self.price = price
        self.currency = currency
        self.priceInclusive = priceInclusive
        self.location = location
        self.bedrooms = bedrooms
        self.bathrooms = bathrooms
        self.areaSqft = areaSqft
        self.publishedAt = publishedAt
        self.lastContactedAt = lastContactedAt
        self.tags = tags
        self.images = images
        self.contactOptions = contactOptions
    }
}

enum ListingTag: String, CaseIterable, Sendable {
    case verified
    case newConstruction = "new_construction"
    case liveViewing = "live_viewing"
    case furnished
    case priceReduced = "price_reduced"
    case seaView = "sea_view"
    case exclusive
    case cornerUnit = "corner_unit"
    case highFloor = "high_floor"
    case lowFloor = "low_floor"
}

enum ContactType: String, CaseIterable, Sendable {
    case phone
    case email
    case whatsApp = "whatsapp"
    case sms
}

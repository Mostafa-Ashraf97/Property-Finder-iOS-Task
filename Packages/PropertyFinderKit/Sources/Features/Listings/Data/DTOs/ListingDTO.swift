import Extensions
import Foundation

struct ListingsResponseDTO: Decodable, Sendable {
    let listings: [ListingDTO]
}

struct ListingDTO: Decodable, Sendable {
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
    let tags: [String]
    let images: [String]
    let contactOptions: [String]
}

extension ListingDTO {
    func toDomainModel() -> Listing {
        Listing(
            id: id,
            type: type,
            deliveryYear: deliveryYear,
            price: price,
            currency: currency,
            priceInclusive: priceInclusive,
            location: location,
            bedrooms: bedrooms,
            bathrooms: bathrooms,
            areaSqft: areaSqft,
            publishedAt: publishedAt,
            lastContactedAt: lastContactedAt,
            tags: tags.compactMap(ListingTag.init(rawValue:)).uniqued(),
            images: images,
            contactOptions: contactOptions.compactMap(ContactType.init(rawValue:)).uniqued()
        )
    }
}

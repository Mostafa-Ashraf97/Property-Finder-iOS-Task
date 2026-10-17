#if DEBUG
    import Foundation

    extension Listing {
        /// A listing with plain defaults; pass only the fields a preview needs.
        static func mock(
            id: String = "mock",
            type: String = "Apartment",
            deliveryYear: Int = 2024,
            price: Int = 1_000_000,
            currency: String = "AED",
            priceInclusive: Bool = false,
            location: String = "Dubai Marina",
            bedrooms: Int? = 1,
            bathrooms: Int = 1,
            areaSqft: Int = 900,
            publishedAt: Date = Date(timeIntervalSince1970: 0),
            lastContactedAt: Date? = nil,
            tags: [ListingTag] = [],
            images: [String] = [],
            contactOptions: [ContactType] = [.phone]
        ) -> Listing {
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
                tags: tags,
                images: images,
                contactOptions: contactOptions
            )
        }

        /// Two listings shaped like the reference design, for previews.
        static let mocks: [Listing] = [
            .mock(
                id: "mock-studio",
                deliveryYear: 2022,
                price: 2_575_000,
                priceInclusive: true,
                location: "Laguna Tower, Lake Almas West, Jumeirah Lake Tower",
                bedrooms: nil,
                areaSqft: 1356,
                publishedAt: .now.addingTimeInterval(-3 * 86400),
                lastContactedAt: Date(timeIntervalSince1970: 1_627_473_600),
                tags: [.verified, .newConstruction, .liveViewing],
                images: ["first_image", "second_image"],
                contactOptions: [.phone, .email, .whatsApp]
            ),
            .mock(
                id: "mock-villa",
                type: "Villa",
                price: 7_900_000,
                location: "Arabian Ranches 3, Dubai",
                bedrooms: 4,
                bathrooms: 5,
                areaSqft: 4210,
                publishedAt: .now.addingTimeInterval(-86400),
                tags: [.verified],
                images: ["second_image", "first_image"],
                contactOptions: [.phone, .whatsApp]
            ),
        ]
    }
#endif

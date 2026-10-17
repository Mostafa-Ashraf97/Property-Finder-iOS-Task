import Foundation

protocol QueryListingsUseCaseProtocol: Sendable {
    func execute(
        listings: [Listing],
        criteria: ListingSearchCriteria,
        favouriteIDs: Set<String>
    ) -> [Listing]
}

struct QueryListingsUseCase {
    init() {}

    private func matchesBedrooms(_ bedrooms: Int?, filter: ListingBedroomFilter) -> Bool {
        switch filter {
        case .any: true
        case .studio: bedrooms == nil
        case let .count(count): bedrooms == count
        }
    }
}

extension QueryListingsUseCase: QueryListingsUseCaseProtocol {
    func execute(
        listings: [Listing],
        criteria: ListingSearchCriteria,
        favouriteIDs: Set<String>
    ) -> [Listing] {
        guard criteria != ListingSearchCriteria() else { return listings }

        let locale = Locale(identifier: "en_AE")
        let tokens = criteria.text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: locale)
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)

        let filters = criteria.filters
        let matches = listings.filter { listing in
            guard !criteria.favouritesOnly || favouriteIDs.contains(listing.id),
                  filters.propertyTypes.isEmpty || filters.propertyTypes.contains(listing.type),
                  matchesBedrooms(listing.bedrooms, filter: filters.bedrooms)
            else { return false }

            guard !tokens.isEmpty else { return true }
            let searchableText = "\(listing.location) \(listing.type)"
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: locale)
            return tokens.allSatisfy { searchableText.contains($0) }
        }

        switch criteria.sortOrder {
        case .recommended:
            return matches
        case .newest:
            return matches.sorted { $0.publishedAt > $1.publishedAt }
        case .priceLowToHigh, .priceHighToLow:
            return matches.sorted { lhs, rhs in
                if lhs.currency != rhs.currency {
                    return lhs.currency < rhs.currency
                }
                return criteria.sortOrder == .priceLowToHigh ? lhs.price < rhs.price : lhs.price > rhs.price
            }
        }
    }
}

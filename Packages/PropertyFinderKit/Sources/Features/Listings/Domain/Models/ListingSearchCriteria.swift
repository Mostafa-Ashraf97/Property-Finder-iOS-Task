import Foundation

struct ListingSearchCriteria: Equatable, Sendable {
    var text = ""
    var filters = ListingFilters()
    var sortOrder: ListingSortOrder = .recommended
    var favouritesOnly = false
}

struct ListingFilters: Equatable, Sendable {
    var propertyTypes: Set<String> = []
    var bedrooms: ListingBedroomFilter = .any

    var activeCount: Int {
        (propertyTypes.isEmpty ? 0 : 1) + (bedrooms == .any ? 0 : 1)
    }
}

enum ListingBedroomFilter: Hashable, Sendable {
    case any
    case studio
    case count(Int)
}

enum ListingSortOrder: String, CaseIterable, Sendable {
    case recommended
    case newest
    case priceLowToHigh
    case priceHighToLow
}

extension ListingSortOrder: Identifiable {
    var id: Self {
        self
    }
}

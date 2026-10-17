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
}

extension QueryListingsUseCase: QueryListingsUseCaseProtocol {
    func execute(
        listings: [Listing],
        criteria: ListingSearchCriteria,
        favouriteIDs: Set<String>
    ) -> [Listing] {
        guard criteria.favouritesOnly else { return listings }
        return listings.filter { favouriteIDs.contains($0.id) }
    }
}

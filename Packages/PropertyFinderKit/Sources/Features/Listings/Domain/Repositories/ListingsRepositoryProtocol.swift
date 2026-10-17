protocol ListingsRepositoryProtocol: Sendable {
    func fetchListings() async throws -> ListingsFeed
}

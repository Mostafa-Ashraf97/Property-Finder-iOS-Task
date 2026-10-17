protocol FetchListingsUseCaseProtocol: Sendable {
    func execute() async throws -> ListingsFeed
}

struct FetchListingsUseCase {
    private let repository: any ListingsRepositoryProtocol

    init(repository: any ListingsRepositoryProtocol) {
        self.repository = repository
    }
}

extension FetchListingsUseCase: FetchListingsUseCaseProtocol {
    func execute() async throws -> ListingsFeed {
        try await repository.fetchListings()
    }
}

import Foundation

protocol FetchListingsUseCaseProtocol: Sendable {
    func execute() async throws -> [Listing]
}

struct FetchListingsUseCase {
    private let repository: any ListingsRepositoryProtocol

    init(repository: any ListingsRepositoryProtocol) {
        self.repository = repository
    }
}

extension FetchListingsUseCase: FetchListingsUseCaseProtocol {
    func execute() async throws -> [Listing] {
        try await repository.fetchListings()
    }
}

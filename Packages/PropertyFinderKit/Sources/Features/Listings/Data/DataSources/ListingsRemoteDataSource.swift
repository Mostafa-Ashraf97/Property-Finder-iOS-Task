import Networking

protocol ListingsRemoteDataSourceProtocol: Sendable {
    func fetchListings() async throws -> ListingsResponseDTO
}

struct ListingsRemoteDataSource {
    private let client: any HTTPClientProtocol

    init(client: any HTTPClientProtocol) {
        self.client = client
    }
}

extension ListingsRemoteDataSource: ListingsRemoteDataSourceProtocol {
    func fetchListings() async throws -> ListingsResponseDTO {
        try await client.request(ListingsEndpoint.listings)
    }
}

import Networking

protocol ListingsRemoteDataSourceProtocol: Sendable {
    func fetchListings(ifNoneMatch etag: String?) async throws -> HTTPResponse
}

struct ListingsRemoteDataSource {
    private let client: any HTTPClientProtocol

    init(client: any HTTPClientProtocol) {
        self.client = client
    }
}

extension ListingsRemoteDataSource: ListingsRemoteDataSourceProtocol {
    func fetchListings(ifNoneMatch etag: String?) async throws -> HTTPResponse {
        try await client.response(for: ListingsEndpoint.listings, ifNoneMatch: etag)
    }
}

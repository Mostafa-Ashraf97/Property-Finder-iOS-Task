import Extensions
import Foundation
import Logger
import Networking

struct ListingsRepository {
    private let remoteDataSource: any ListingsRemoteDataSourceProtocol
    private let localDataSource: any ListingsLocalDataSourceProtocol
    private let logger: any LoggerProtocol

    init(
        remoteDataSource: any ListingsRemoteDataSourceProtocol,
        localDataSource: any ListingsLocalDataSourceProtocol,
        logger: any LoggerProtocol
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.logger = logger
    }

    private func listings(from body: Data) throws -> [Listing] {
        try JSONResponse.decode(ListingsResponseDTO.self, from: body).listings
            .filter { !$0.id.isBlank }
            .uniqued(by: \.id)
            .map { $0.toDomainModel() }
    }

    private func mapError(_ error: any Error) -> ListingsError {
        switch error {
        case let error as URLError:
            switch error.code {
            case .timedOut: .timedOut
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
                .connection
            default: .unexpected
            }
        case HTTPClientError.statusCode: .serviceUnavailable
        case is DecodingError, HTTPClientError.invalidResponse: .invalidData
        default: .unexpected
        }
    }
}

extension ListingsRepository: ListingsRepositoryProtocol {
    func fetchListings() async throws -> ListingsFeed {
        let cached = localDataSource.load()
        do {
            let response = try await remoteDataSource.fetchListings(ifNoneMatch: cached?.etag)
            let body = response.isNotModified ? cached?.body ?? response.data : response.data
            let listings = try listings(from: body)
            try Task.checkCancellation()
            let etag = response.isNotModified ? response.etag ?? cached?.etag : response.etag
            localDataSource.save(CachedListingsResponse(body: body, etag: etag))
            return ListingsFeed(listings: listings, isStale: false)
        } catch {
            if Task.isCancelled || error.isCancellation {
                throw CancellationError()
            }
            logger.error("Fetching listings failed", private: String(describing: error))
            let failure = mapError(error)
            if failure == .connection || failure == .timedOut, let cached, let listings = try? listings(from: cached.body) {
                return ListingsFeed(listings: listings, isStale: true)
            }
            throw failure
        }
    }
}

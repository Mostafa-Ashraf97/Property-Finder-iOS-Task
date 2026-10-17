import Extensions
import Foundation
import Logger
import Networking

struct ListingsRepository {
    private let remoteDataSource: any ListingsRemoteDataSourceProtocol
    private let logger: any LoggerProtocol

    init(remoteDataSource: any ListingsRemoteDataSourceProtocol, logger: any LoggerProtocol) {
        self.remoteDataSource = remoteDataSource
        self.logger = logger
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
    func fetchListings() async throws -> [Listing] {
        let response: ListingsResponseDTO
        do {
            response = try await remoteDataSource.fetchListings()
        } catch {
            if Task.isCancelled || error.isCancellation {
                throw CancellationError()
            }
            logger.error("Fetching listings failed: \(error)")
            throw mapError(error)
        }

        return response.listings
            .filter { !$0.id.isBlank }
            .uniqued(by: \.id)
            .map { $0.toDomainModel() }
    }
}

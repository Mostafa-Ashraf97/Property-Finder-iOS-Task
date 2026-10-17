import Foundation
import Logger
import Networking

@MainActor
public struct ListingsFactory {
    private let httpClient: any HTTPClientProtocol
    private let logger: LoggerProtocol

    public init(httpClient: any HTTPClientProtocol, logger: LoggerProtocol) {
        self.httpClient = httpClient
        self.logger = logger
    }

    public func makeListingsView() -> ListingsView {
        let listingsRepository = ListingsRepository(
            remoteDataSource: ListingsRemoteDataSource(client: httpClient),
            logger: logger
        )
        let fetchListingsUseCase = FetchListingsUseCase(repository: listingsRepository)

        let viewModel = ListingsViewModel(
            fetchListingsUseCase: fetchListingsUseCase,
            logger: logger
        )
        let listingView = ListingsView(viewModel: viewModel)

        return listingView
    }
}

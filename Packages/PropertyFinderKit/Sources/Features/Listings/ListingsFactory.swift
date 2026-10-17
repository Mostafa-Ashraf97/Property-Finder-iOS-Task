import Foundation
import Logger
import Networking

@MainActor
public struct ListingsFactory {
    private let httpClient: any HTTPClientProtocol
    private let defaults: UserDefaults
    private let logger: LoggerProtocol

    public init(httpClient: any HTTPClientProtocol, defaults: UserDefaults, logger: LoggerProtocol) {
        self.httpClient = httpClient
        self.defaults = defaults
        self.logger = logger
    }

    public func makeListingsView() -> ListingsView {
        let listingsRepository = ListingsRepository(
            remoteDataSource: ListingsRemoteDataSource(client: httpClient),
            logger: logger
        )
        let favouritesRepository = FavouritesRepository(
            localDataSource: FavouritesLocalDataSource(defaults: defaults)
        )
        let loadFavouritesUseCase = LoadFavouritesUseCase(repository: favouritesRepository)
        let toggleFavouriteUseCase = ToggleFavouriteUseCase(repository: favouritesRepository)
        let fetchListingsUseCase = FetchListingsUseCase(repository: listingsRepository)
        let queryListingsUseCase = QueryListingsUseCase()

        let viewModel = ListingsViewModel(
            fetchListingsUseCase: fetchListingsUseCase,
            loadFavouritesUseCase: loadFavouritesUseCase,
            toggleFavouriteUseCase: toggleFavouriteUseCase,
            queryListingsUseCase: queryListingsUseCase,
            logger: logger
        )
        let listingView = ListingsView(viewModel: viewModel)

        return listingView
    }
}

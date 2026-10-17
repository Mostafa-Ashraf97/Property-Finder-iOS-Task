import Foundation
import Logger
import Networking
import Services

@MainActor
public struct ListingsFactory {
    private let httpClient: any HTTPClientProtocol
    private let defaults: UserDefaults
    private let logger: LoggerProtocol
    private let networkMonitor: any NetworkMonitorProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let analyticsTracker: any AnalyticsTrackerProtocol

    public init(
        httpClient: any HTTPClientProtocol,
        defaults: UserDefaults,
        logger: LoggerProtocol,
        networkMonitor: any NetworkMonitorProtocol,
        featureFlagProvider: any FeatureFlagProviderProtocol,
        analyticsTracker: any AnalyticsTrackerProtocol
    ) {
        self.httpClient = httpClient
        self.defaults = defaults
        self.logger = logger
        self.networkMonitor = networkMonitor
        self.featureFlagProvider = featureFlagProvider
        self.analyticsTracker = analyticsTracker
    }

    public func makeListingsView() -> ListingsView {
        let listingsRepository = ListingsRepository(
            remoteDataSource: ListingsRemoteDataSource(client: httpClient),
            localDataSource: ListingsLocalDataSource(),
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
            networkMonitor: networkMonitor,
            featureFlags: featureFlagProvider,
            logger: logger
        )
        let decoratedViewModel = ListingsViewModelAnalyticsDecorator(decoratee: viewModel, tracker: analyticsTracker)
        return ListingsView(viewModel: decoratedViewModel)
    }
}

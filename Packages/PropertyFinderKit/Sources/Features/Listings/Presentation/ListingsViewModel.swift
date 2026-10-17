import Extensions
import Foundation
import Logger
import Networking
import Observation
import Services

@MainActor
protocol ListingsViewModelProtocol: AnyObject, Observable {
    var state: ListingsViewState { get }
    var criteria: ListingSearchCriteria { get set }
    var isFilterEnabled: Bool { get }
    var isSortEnabled: Bool { get }
    var resultsSummary: String? { get }
    var availablePropertyTypes: [String] { get }
    var availableBedroomCounts: [Int] { get }
    var refreshMessage: String? { get }
    var isShowingSavedListings: Bool { get }

    func load() async
    func refresh() async
    func observeUpdates() async
    func matchingCount(for filters: ListingFilters) -> Int
    func clearSearchAndFilters()
    func toggleFavourite(id: String)
    func contact(_ type: ContactType, listingID: String)
}

@MainActor
@Observable
final class ListingsViewModel {
    private(set) var state: ListingsViewState = .loading
    private(set) var refreshMessage: String?
    private(set) var isShowingSavedListings = false
    var criteria = ListingSearchCriteria() {
        didSet {
            if criteria != oldValue, hasLoaded {
                updateState()
            }
        }
    }

    private var listings: [Listing] = []
    private var favouriteIDs: Set<String> = []
    @ObservationIgnored private var fetchTask: Task<Void, Never>?

    private let fetchListingsUseCase: any FetchListingsUseCaseProtocol
    private let loadFavouritesUseCase: any LoadFavouritesUseCaseProtocol
    private let toggleFavouriteUseCase: any ToggleFavouriteUseCaseProtocol
    private let queryListingsUseCase: any QueryListingsUseCaseProtocol
    private let networkMonitor: any NetworkMonitorProtocol
    private let featureFlags: any FeatureFlagProviderProtocol
    private let logger: any LoggerProtocol

    init(
        fetchListingsUseCase: any FetchListingsUseCaseProtocol,
        loadFavouritesUseCase: any LoadFavouritesUseCaseProtocol,
        toggleFavouriteUseCase: any ToggleFavouriteUseCaseProtocol,
        queryListingsUseCase: any QueryListingsUseCaseProtocol,
        networkMonitor: any NetworkMonitorProtocol,
        featureFlags: any FeatureFlagProviderProtocol,
        logger: any LoggerProtocol
    ) {
        self.fetchListingsUseCase = fetchListingsUseCase
        self.loadFavouritesUseCase = loadFavouritesUseCase
        self.toggleFavouriteUseCase = toggleFavouriteUseCase
        self.queryListingsUseCase = queryListingsUseCase
        self.networkMonitor = networkMonitor
        self.featureFlags = featureFlags
        self.logger = logger
    }

    private var hasLoaded: Bool {
        switch state {
        case .loading, .failed: false
        case .noListings, .noFavourites, .noMatches, .results: true
        }
    }

    private var savedCount: Int {
        listings.count { favouriteIDs.contains($0.id) }
    }

    private func updateState() {
        guard !listings.isEmpty else {
            state = .noListings
            return
        }

        let matches = queryListingsUseCase.execute(listings: listings, criteria: criteria, favouriteIDs: favouriteIDs)
        let cards = matches.map { ListingCardViewData(listing: $0, isFavourite: favouriteIDs.contains($0.id)) }
        if cards.isEmpty {
            state = criteria.favouritesOnly && savedCount == 0 ? .noFavourites : .noMatches
        } else {
            state = .results(cards)
        }
    }

    private func apply(_ feed: ListingsFeed) {
        listings = feed.listings
        isShowingSavedListings = feed.isStale
        refreshMessage = nil
        updateState()
    }

    private func fetchListings() async {
        if let fetchTask {
            await fetchTask.value
            return
        }

        let task = Task {
            await performFetch()
        }

        fetchTask = task
        defer { fetchTask = nil }

        await task.value
    }

    private func performFetch() async {
        let isRefresh = hasLoaded
        refreshMessage = nil
        if !isRefresh {
            state = .loading
            favouriteIDs = loadFavouritesUseCase.execute()
        }

        do {
            let feed = try await fetchListingsUseCase.execute()
            try Task.checkCancellation()
            apply(feed)
        } catch {
            guard !Task.isCancelled, !error.isCancellation else { return }
            if isRefresh {
                refreshMessage = "Couldn't refresh properties. Showing previous results. Pull down to try again."
            } else {
                state = .failed(error as? ListingsError ?? .unexpected)
            }
        }
    }
}

extension ListingsViewModel: ListingsViewModelProtocol {
    var isFilterEnabled: Bool {
        featureFlags.isEnabled(.listingsFiltersEnabled, defaultValue: false)
    }

    var isSortEnabled: Bool {
        featureFlags.isEnabled(.listingsSortEnabled, defaultValue: false)
    }

    var resultsSummary: String? {
        let isNarrowed = criteria.favouritesOnly || !criteria.text.isBlank || criteria.filters.activeCount > 0
        guard isNarrowed, hasLoaded else { return nil }

        let total = criteria.favouritesOnly ? savedCount : listings.count
        let collection = criteria.favouritesOnly
            ? total.counted("saved property", plural: "saved properties")
            : total.counted("property", plural: "properties")
        let shown = switch state {
        case let .results(cards): cards.count
        default: 0
        }
        return shown == total ? collection : "\(shown) of \(collection)"
    }

    var availablePropertyTypes: [String] {
        listings.map(\.type).uniqued().sorted()
    }

    var availableBedroomCounts: [Int] {
        listings.compactMap(\.bedrooms).uniqued().sorted()
    }

    func load() async {
        guard !hasLoaded else { return }
        await fetchListings()
    }

    func refresh() async {
        guard hasLoaded else { return }
        await fetchListings()
    }

    /// Fetches again when the connection comes back, if the screen shows saved listings or a failed load.
    func observeUpdates() async {
        var wasOffline = false
        for await isOnline in networkMonitor.updates() {
            if isOnline, wasOffline {
                if isShowingSavedListings {
                    await refresh()
                } else if case .failed = state {
                    await load()
                }
            }
            wasOffline = !isOnline
        }
    }

    func matchingCount(for filters: ListingFilters) -> Int {
        var previewCriteria = criteria
        previewCriteria.filters = filters
        return queryListingsUseCase.execute(listings: listings, criteria: previewCriteria, favouriteIDs: favouriteIDs).count
    }

    func clearSearchAndFilters() {
        var updatedCriteria = criteria
        updatedCriteria.text = ""
        updatedCriteria.filters = ListingFilters()
        criteria = updatedCriteria
    }

    func toggleFavourite(id: String) {
        favouriteIDs = toggleFavouriteUseCase.execute(id: id, currentIDs: favouriteIDs)
        if hasLoaded {
            updateState()
        }
    }

    func contact(_ type: ContactType, listingID: String) {
        logger.info("Contact \(type.rawValue)", private: listingID)
    }
}

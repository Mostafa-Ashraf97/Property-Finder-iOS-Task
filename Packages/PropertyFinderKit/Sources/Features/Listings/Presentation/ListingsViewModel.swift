import Extensions
import Logger
import Observation

@MainActor
protocol ListingsViewModelProtocol: AnyObject, Observable {
    var state: ListingsViewState { get }
    var criteria: ListingSearchCriteria { get set }
    var resultsSummary: String? { get }
    var availablePropertyTypes: [String] { get }
    var availableBedroomCounts: [Int] { get }
    var refreshMessage: String? { get }

    func load() async
    func refresh() async
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
    var criteria = ListingSearchCriteria() {
        didSet {
            if criteria != oldValue, hasLoaded {
                updateState()
            }
        }
    }

    private var listings: [Listing] = []
    private var favouriteIDs: Set<String> = []

    private let fetchListingsUseCase: any FetchListingsUseCaseProtocol
    private let loadFavouritesUseCase: any LoadFavouritesUseCaseProtocol
    private let toggleFavouriteUseCase: any ToggleFavouriteUseCaseProtocol
    private let queryListingsUseCase: any QueryListingsUseCaseProtocol
    private let logger: any LoggerProtocol

    init(
        fetchListingsUseCase: any FetchListingsUseCaseProtocol,
        loadFavouritesUseCase: any LoadFavouritesUseCaseProtocol,
        toggleFavouriteUseCase: any ToggleFavouriteUseCaseProtocol,
        queryListingsUseCase: any QueryListingsUseCaseProtocol,
        logger: any LoggerProtocol
    ) {
        self.fetchListingsUseCase = fetchListingsUseCase
        self.loadFavouritesUseCase = loadFavouritesUseCase
        self.toggleFavouriteUseCase = toggleFavouriteUseCase
        self.queryListingsUseCase = queryListingsUseCase
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

    private func fetchListings() async {
        let isRefresh = hasLoaded
        refreshMessage = nil
        if !isRefresh {
            state = .loading
            favouriteIDs = loadFavouritesUseCase.execute()
        }

        do {
            let listings = try await fetchListingsUseCase.execute()
            try Task.checkCancellation()
            self.listings = listings
            updateState()
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
        logger.info("Contact \(type.rawValue) for \(listingID)")
    }
}

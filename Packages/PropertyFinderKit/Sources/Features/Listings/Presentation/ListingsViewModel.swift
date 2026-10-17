import Extensions
import Logger
import Observation

@MainActor
protocol ListingsViewModelProtocol: AnyObject, Observable {
    var state: ListingsViewState { get }
    var refreshMessage: String? { get }

    func load() async
    func refresh() async
    func toggleFavourite(id: String)
    func logAction(_ action: String)
    func contact(_ type: ContactType, listingID: String)
}

@MainActor
@Observable
final class ListingsViewModel {
    private(set) var state: ListingsViewState = .loading
    private(set) var refreshMessage: String?

    private let fetchListingsUseCase: any FetchListingsUseCaseProtocol
    private let logger: any LoggerProtocol

    init(
        fetchListingsUseCase: any FetchListingsUseCaseProtocol,
        logger: any LoggerProtocol
    ) {
        self.fetchListingsUseCase = fetchListingsUseCase
        self.logger = logger
    }

    private var hasLoaded: Bool {
        switch state {
        case .loading, .failed: false
        case .noListings, .results: true
        }
    }

    private func fetchListings() async {
        let isRefresh = hasLoaded
        refreshMessage = nil
        if !isRefresh {
            state = .loading
        }

        do {
            let listings = try await fetchListingsUseCase.execute()
            try Task.checkCancellation()
            let cards = listings.map { ListingCardViewData(listing: $0, isFavourite: false) }
            state = cards.isEmpty ? .noListings : .results(cards)
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
    func load() async {
        guard !hasLoaded else { return }
        await fetchListings()
    }

    func refresh() async {
        guard hasLoaded else { return }
        await fetchListings()
    }

    func toggleFavourite(id: String) {
        logger.info("Favourite tapped for \(id)")
    }

    func logAction(_ action: String) {
        logger.info(action, privacy: .public)
    }

    func contact(_ type: ContactType, listingID: String) {
        logger.info("Contact \(type.rawValue) for \(listingID)")
    }
}

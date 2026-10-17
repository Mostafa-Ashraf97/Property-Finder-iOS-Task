import Services

@MainActor
final class ListingsViewModelAnalyticsDecorator {
    private let decoratee: any ListingsViewModelProtocol
    private let tracker: any AnalyticsTrackerProtocol

    init(decoratee: any ListingsViewModelProtocol, tracker: any AnalyticsTrackerProtocol) {
        self.decoratee = decoratee
        self.tracker = tracker
    }
}

extension ListingsViewModelAnalyticsDecorator: ListingsViewModelProtocol {
    var state: ListingsViewState {
        decoratee.state
    }

    var criteria: ListingSearchCriteria {
        get { decoratee.criteria }
        set { decoratee.criteria = newValue }
    }

    var isFilterEnabled: Bool {
        decoratee.isFilterEnabled
    }

    var isSortEnabled: Bool {
        decoratee.isSortEnabled
    }

    var resultsSummary: String? {
        decoratee.resultsSummary
    }

    var availablePropertyTypes: [String] {
        decoratee.availablePropertyTypes
    }

    var availableBedroomCounts: [Int] {
        decoratee.availableBedroomCounts
    }

    var refreshMessage: String? {
        decoratee.refreshMessage
    }

    var isShowingSavedListings: Bool {
        decoratee.isShowingSavedListings
    }

    func load() async {
        await decoratee.load()
    }

    func refresh() async {
        await decoratee.refresh()
    }

    func observeUpdates() async {
        await decoratee.observeUpdates()
    }

    func matchingCount(for filters: ListingFilters) -> Int {
        decoratee.matchingCount(for: filters)
    }

    func clearSearchAndFilters() {
        decoratee.clearSearchAndFilters()
    }

    func toggleFavourite(id: String) {
        decoratee.toggleFavourite(id: id)
        tracker.track(ListingsAnalyticsEvent.favouriteTapped())
    }

    func contact(_ type: ContactType, listingID: String) {
        decoratee.contact(type, listingID: listingID)
        tracker.track(ListingsAnalyticsEvent.contactTapped(type: type.rawValue))
    }
}

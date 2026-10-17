#if DEBUG
    import Observation

    @MainActor
    @Observable
    final class ListingsViewModelMock {
        var state: ListingsViewState
        var criteria: ListingSearchCriteria
        var resultsSummary: String?
        var refreshMessage: String?

        init(
            state: ListingsViewState = .results(ListingCardViewData.mocks),
            criteria: ListingSearchCriteria = ListingSearchCriteria(),
            resultsSummary: String? = nil
        ) {
            self.state = state
            self.criteria = criteria
            self.resultsSummary = resultsSummary
        }
    }

    extension ListingsViewModelMock: ListingsViewModelProtocol {
        func load() async {}

        func refresh() async {}

        func toggleFavourite(id _: String) {}

        func logAction(_: String) {}

        func contact(_: ContactType, listingID _: String) {}
    }
#endif

#if DEBUG
    import Observation

    @MainActor
    @Observable
    final class ListingsViewModelMock {
        var state: ListingsViewState
        var criteria: ListingSearchCriteria
        var resultsSummary: String?
        var refreshMessage: String?
        let availablePropertyTypes = ["Apartment", "Townhouse", "Villa"]
        let availableBedroomCounts = [1, 2, 3, 4]

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

        func matchingCount(for _: ListingFilters) -> Int {
            guard case let .results(cards) = state else { return 0 }
            return cards.count
        }

        func clearSearchAndFilters() {
            criteria.text = ""
            criteria.filters = ListingFilters()
        }

        func toggleFavourite(id _: String) {}

        func contact(_: ContactType, listingID _: String) {}
    }
#endif

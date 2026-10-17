#if DEBUG
    import Observation

    @MainActor
    @Observable
    final class ListingsViewModelMock {
        var state: ListingsViewState
        var refreshMessage: String?

        init(state: ListingsViewState = .results(ListingCardViewData.mocks)) {
            self.state = state
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

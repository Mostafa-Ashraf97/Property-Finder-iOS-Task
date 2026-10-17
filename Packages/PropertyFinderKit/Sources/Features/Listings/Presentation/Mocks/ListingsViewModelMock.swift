import Observation

@MainActor
@Observable
final class ListingsViewModelMock: ListingsViewModelProtocol {
    let state = ListingsViewState.results([
        ListingCardViewData(
            id: "preview-property",
            images: ["first_image", "second_image"],
            tags: [.verified, .newConstruction, .liveViewing],
            isFavourite: false,
            propertyType: "Apartment",
            delivery: "Delivery: 2022",
            price: "2,575,000 AED",
            location: "Laguna Tower, Lake Almas West, Jumeirah Lake Tower",
            bedrooms: "1 Bed",
            bathrooms: "1 Bath",
            area: "1,356 sqft",
            published: "Published 3 days ago",
            lastContacted: "Last contacted: 28 Jun 2021",
            contactOptions: [.phone, .email, .whatsApp]
        ),
    ])
    var criteria = ListingSearchCriteria()
    let resultsSummary: String? = nil
    let refreshMessage: String? = nil
    let isShowingSavedListings = false
    let isFilterEnabled = true
    let isSortEnabled = true
    let availablePropertyTypes = ["Apartment"]
    let availableBedroomCounts = [1]

    func load() async {}

    func refresh() async {}

    func observeUpdates() async {}

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

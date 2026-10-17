enum ListingsViewState: Equatable {
    case loading
    case failed(ListingsError)
    case noListings
    case noFavourites
    case results([ListingCardViewData])
}

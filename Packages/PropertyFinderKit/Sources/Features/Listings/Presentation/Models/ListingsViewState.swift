enum ListingsViewState: Equatable {
    case loading
    case failed(ListingsError)
    case noListings
    case noFavourites
    case noMatches
    case results([ListingCardViewData])
}

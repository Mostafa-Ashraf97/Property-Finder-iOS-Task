#if DEBUG
    extension ListingCardViewData {
        static let mocks: [ListingCardViewData] = Listing.mocks.map { listing in
            ListingCardViewData(listing: listing, isFavourite: listing.id == "mock-studio")
        }
    }
#endif

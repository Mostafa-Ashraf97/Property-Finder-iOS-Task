struct ListingsFeed: Equatable, Sendable {
    let listings: [Listing]
    let isStale: Bool
}

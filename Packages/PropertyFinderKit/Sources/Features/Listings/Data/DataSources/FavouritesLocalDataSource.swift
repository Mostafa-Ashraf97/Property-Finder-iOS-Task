import Foundation

@MainActor
protocol FavouritesLocalDataSourceProtocol {
    func loadIDs() -> [String]
    func saveIDs(_ ids: [String])
}

struct FavouritesLocalDataSource {
    static let key = "ae.propertyfinder.Tahudu.favouriteListingIDs"

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }
}

extension FavouritesLocalDataSource: FavouritesLocalDataSourceProtocol {
    func loadIDs() -> [String] {
        defaults.stringArray(forKey: Self.key) ?? []
    }

    func saveIDs(_ ids: [String]) {
        defaults.set(ids, forKey: Self.key)
    }
}

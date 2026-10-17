import Foundation

struct FavouritesRepository {
    private let localDataSource: any FavouritesLocalDataSourceProtocol

    init(localDataSource: any FavouritesLocalDataSourceProtocol) {
        self.localDataSource = localDataSource
    }
}

extension FavouritesRepository: FavouritesRepositoryProtocol {
    func loadIDs() -> Set<String> {
        Set(localDataSource.loadIDs())
    }

    func saveIDs(_ ids: Set<String>) {
        localDataSource.saveIDs(Array(ids))
    }
}

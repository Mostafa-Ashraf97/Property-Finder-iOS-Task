import Foundation

@MainActor
protocol FavouritesRepositoryProtocol {
    func loadIDs() -> Set<String>
    func saveIDs(_ ids: Set<String>)
}

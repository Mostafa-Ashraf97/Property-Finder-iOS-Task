import Foundation

@MainActor
protocol LoadFavouritesUseCaseProtocol {
    func execute() -> Set<String>
}

struct LoadFavouritesUseCase {
    private let repository: any FavouritesRepositoryProtocol

    init(repository: any FavouritesRepositoryProtocol) {
        self.repository = repository
    }
}

extension LoadFavouritesUseCase: LoadFavouritesUseCaseProtocol {
    func execute() -> Set<String> {
        repository.loadIDs()
    }
}

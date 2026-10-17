import Foundation

@MainActor
protocol ToggleFavouriteUseCaseProtocol {
    func execute(id: String, currentIDs: Set<String>) -> Set<String>
}

struct ToggleFavouriteUseCase {
    private let repository: any FavouritesRepositoryProtocol

    init(repository: any FavouritesRepositoryProtocol) {
        self.repository = repository
    }
}

extension ToggleFavouriteUseCase: ToggleFavouriteUseCaseProtocol {
    func execute(id: String, currentIDs: Set<String>) -> Set<String> {
        var updatedIDs = currentIDs
        if !updatedIDs.insert(id).inserted {
            updatedIDs.remove(id)
        }
        repository.saveIDs(updatedIDs)
        return updatedIDs
    }
}

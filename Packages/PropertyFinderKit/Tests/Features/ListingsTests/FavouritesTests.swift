import Foundation
@testable import Listings
import Testing

@MainActor
struct FavouritesTests {
    @Test func persistsFavouritesAcrossRepositoryInstances() throws {
        let (defaults, suite) = try isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }

        makeRepository(defaults).saveIDs(["prop_002", "prop_001"])

        #expect(makeRepository(defaults).loadIDs() == ["prop_001", "prop_002"])
    }

    @Test func startsEmpty() throws {
        let (defaults, suite) = try isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }

        #expect(makeRepository(defaults).loadIDs().isEmpty)
    }

    @Test func toggleAddsThenRemovesAndPersistsEachChange() {
        let repository = InMemoryFavouritesRepository()
        let toggle = ToggleFavouriteUseCase(repository: repository)

        let added = toggle.execute(id: "prop_001", currentIDs: ["prop_009"])
        #expect(added == ["prop_001", "prop_009"])
        #expect(repository.ids == added)

        let removed = toggle.execute(id: "prop_001", currentIDs: added)
        #expect(removed == ["prop_009"])
        #expect(repository.ids == removed)
        #expect(repository.saveCount == 2)
    }

    @Test func eachTogglePersistsAllCurrentlySavedIDs() throws {
        let (defaults, suite) = try isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = makeRepository(defaults)
        let toggle = ToggleFavouriteUseCase(repository: repository)

        let first = toggle.execute(id: "prop_001", currentIDs: [])
        #expect(defaults.stringArray(forKey: FavouritesLocalDataSource.key) == ["prop_001"])

        let second = toggle.execute(id: "prop_007", currentIDs: first)
        #expect(Set(defaults.stringArray(forKey: FavouritesLocalDataSource.key) ?? []) == ["prop_001", "prop_007"])

        _ = toggle.execute(id: "prop_001", currentIDs: second)
        #expect(defaults.stringArray(forKey: FavouritesLocalDataSource.key) == ["prop_007"])
    }

    private func makeRepository(_ defaults: UserDefaults) -> FavouritesRepository {
        FavouritesRepository(localDataSource: FavouritesLocalDataSource(defaults: defaults))
    }

    private func isolatedDefaults() throws -> (UserDefaults, String) {
        let suite = "FavouritesTests.\(UUID().uuidString)"
        return try (#require(UserDefaults(suiteName: suite)), suite)
    }
}

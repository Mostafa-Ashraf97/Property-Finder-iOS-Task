import Foundation
@testable import Listings
import XCTest

@MainActor
final class FavouritesTests: XCTestCase {
    func test_toggleFavourite_whenNotSaved_addsAndSavesIt() {
        // Given
        let repository = InMemoryFavouritesRepository()
        let toggle = ToggleFavouriteUseCase(repository: repository)

        // When
        let ids = toggle.execute(id: "a", currentIDs: [])

        // Then
        XCTAssertEqual(ids, ["a"])
        XCTAssertEqual(repository.ids, ["a"])
    }

    func test_toggleFavourite_whenSaved_removesAndSavesIt() {
        // Given
        let repository = InMemoryFavouritesRepository(ids: ["a"])
        let toggle = ToggleFavouriteUseCase(repository: repository)

        // When
        let ids = toggle.execute(id: "a", currentIDs: ["a"])

        // Then
        XCTAssertEqual(ids, [])
        XCTAssertEqual(repository.ids, [])
        XCTAssertEqual(repository.saveCount, 1)
    }

    func test_loadIDs_afterSaving_returnsThemFromANewRepository() throws {
        // Given
        let suiteName = "FavouritesTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        FavouritesRepository(localDataSource: FavouritesLocalDataSource(defaults: defaults)).saveIDs(["a", "b"])

        // When
        let ids = FavouritesRepository(localDataSource: FavouritesLocalDataSource(defaults: defaults)).loadIDs()

        // Then
        XCTAssertEqual(ids, ["a", "b"])
    }
}

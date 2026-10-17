import Foundation
@testable import Listings
import XCTest

final class ListingsLocalDataSourceTests: XCTestCase {
    private let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("listings-\(UUID().uuidString).json")

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL)
        super.tearDown()
    }

    func test_load_afterSaving_returnsTheSavedResponseFromANewInstance() {
        // Given
        let response = CachedListingsResponse(body: Data("{}".utf8), etag: "v1")
        ListingsLocalDataSource(fileURL: fileURL).save(response)

        // When
        let loaded = ListingsLocalDataSource(fileURL: fileURL).load()

        // Then
        XCTAssertEqual(loaded, response)
    }

    func test_load_beforeAnySave_returnsNil() {
        // When
        let loaded = ListingsLocalDataSource(fileURL: fileURL).load()

        // Then
        XCTAssertNil(loaded)
    }

    func test_load_whenTheFileIsUnreadable_returnsNil() throws {
        // Given
        try Data("not a saved response".utf8).write(to: fileURL)

        // When
        let loaded = ListingsLocalDataSource(fileURL: fileURL).load()

        // Then
        XCTAssertNil(loaded)
    }
}

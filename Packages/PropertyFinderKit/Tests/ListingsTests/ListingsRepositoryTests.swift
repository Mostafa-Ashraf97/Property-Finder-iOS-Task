import Foundation
@testable import Listings
import Networking
import XCTest

final class ListingsRepositoryTests: XCTestCase {
    func test_fetchListings_whenTheServerReturnsListings_returnsThemAndSavesTheBodyWithItsETag() async throws {
        // Given
        let body = try listingsBody([listingJSON(id: "a"), listingJSON(id: "b")])
        let cache = InMemoryListingsCache()
        let repository = makeRepository(remote: .returning(HTTPResponse(statusCode: 200, data: body, etag: "v1")), cache: cache)

        // When
        let feed = try await repository.fetchListings()

        // Then
        XCTAssertEqual(feed.listings.map(\.id), ["a", "b"])
        XCTAssertFalse(feed.isStale)
        XCTAssertEqual(cache.saved, CachedListingsResponse(body: body, etag: "v1"))
    }

    func test_fetchListings_mapsTheDocumentedFields() async throws {
        // Given
        let body = try listingsBody([listingJSON(id: "a", overrides: [
            "bedrooms": NSNull(),
            "lastContactedAt": "2021-07-28T12:00:00Z",
            "tags": ["verified", "rooftop_pool"],
            "contactOptions": ["phone", "fax", "whatsapp"],
        ])])
        let repository = makeRepository(remote: .returning(HTTPResponse(statusCode: 200, data: body)))

        // When
        let feed = try await repository.fetchListings()

        // Then
        let listing = try XCTUnwrap(feed.listings.first)
        XCTAssertNil(listing.bedrooms, "A null bedroom count means a studio")
        XCTAssertEqual(listing.price, 2_575_000)
        XCTAssertEqual(listing.publishedAt, try date("2024-11-28T12:00:00Z"))
        XCTAssertEqual(listing.lastContactedAt, try date("2021-07-28T12:00:00Z"))
        XCTAssertEqual(listing.tags, [.verified], "Unknown tags are dropped")
        XCTAssertEqual(listing.contactOptions, [.phone, .whatsApp], "Unknown contact options are dropped")
    }

    func test_fetchListings_whenNotModified_sendsTheSavedETagAndReturnsTheSavedListings() async throws {
        // Given
        let remote = StubRemoteDataSource.returning(HTTPResponse(statusCode: 304, data: Data(), etag: "v1"))
        let repository = try makeRepository(remote: remote, cache: InMemoryListingsCache(savedCopy()))

        // When
        let feed = try await repository.fetchListings()

        // Then
        XCTAssertEqual(remote.receivedETags, ["v1"])
        XCTAssertEqual(feed.listings.map(\.id), ["saved"])
        XCTAssertFalse(feed.isStale)
    }

    func test_fetchListings_whenOffline_returnsTheSavedCopy() async throws {
        // Given
        let repository = try makeRepository(
            remote: .failing(URLError(.notConnectedToInternet)),
            cache: InMemoryListingsCache(savedCopy())
        )

        // When
        let feed = try await repository.fetchListings()

        // Then
        XCTAssertEqual(feed.listings.map(\.id), ["saved"])
        XCTAssertTrue(feed.isStale)
    }

    func test_fetchListings_whenTheRequestTimesOut_returnsTheSavedCopy() async throws {
        // Given
        let repository = try makeRepository(remote: .failing(URLError(.timedOut)), cache: InMemoryListingsCache(savedCopy()))

        // When
        let feed = try await repository.fetchListings()

        // Then
        XCTAssertTrue(feed.isStale)
    }

    func test_fetchListings_whenOfflineWithNothingSaved_throwsConnection() async {
        // Given
        let repository = makeRepository(remote: .failing(URLError(.notConnectedToInternet)))

        // When / Then
        await assertThrows(ListingsError.connection) { try await repository.fetchListings() }
    }

    func test_fetchListings_whenTheServerFails_throwsInsteadOfUsingTheSavedCopy() async throws {
        // Given
        let repository = try makeRepository(
            remote: .failing(HTTPClientError.statusCode(503)),
            cache: InMemoryListingsCache(savedCopy())
        )

        // When / Then
        await assertThrows(ListingsError.serviceUnavailable) { try await repository.fetchListings() }
    }

    func test_fetchListings_whenTheNewBodyIsMalformed_throwsAndKeepsTheSavedCopy() async throws {
        // Given
        let saved = try savedCopy()
        let cache = InMemoryListingsCache(saved)
        let repository = makeRepository(
            remote: .returning(HTTPResponse(statusCode: 200, data: Data("not json".utf8), etag: "v2")),
            cache: cache
        )

        // When / Then
        await assertThrows(ListingsError.invalidData) { try await repository.fetchListings() }
        XCTAssertEqual(cache.saved, saved)
    }

    func test_fetchListings_withBlankOrDuplicateIDs_dropsThemKeepingTheFirst() async throws {
        // Given
        let body = try listingsBody([
            listingJSON(id: "a", price: 1),
            listingJSON(id: " "),
            listingJSON(id: "a", price: 2),
            listingJSON(id: "b"),
        ])
        let repository = makeRepository(remote: .returning(HTTPResponse(statusCode: 200, data: body)))

        // When
        let feed = try await repository.fetchListings()

        // Then
        XCTAssertEqual(feed.listings.map(\.id), ["a", "b"])
        XCTAssertEqual(feed.listings.first?.price, 1)
    }

    func test_fetchListings_whenCancelled_rethrowsCancellationWithoutLogging() async {
        // Given
        let logger = SpyLogger()
        let repository = makeRepository(remote: .failing(URLError(.cancelled)), logger: logger)

        // When
        var thrownError: (any Error)?
        do {
            _ = try await repository.fetchListings()
        } catch {
            thrownError = error
        }

        // Then
        XCTAssertTrue(thrownError is CancellationError)
        XCTAssertTrue(logger.loggedEntries.isEmpty)
    }

    private func savedCopy() throws -> CachedListingsResponse {
        try CachedListingsResponse(body: listingsBody([listingJSON(id: "saved")]), etag: "v1")
    }

    private func makeRepository(
        remote: StubRemoteDataSource,
        cache: InMemoryListingsCache = InMemoryListingsCache(),
        logger: SpyLogger = SpyLogger()
    ) -> ListingsRepository {
        ListingsRepository(remoteDataSource: remote, localDataSource: cache, logger: logger)
    }
}

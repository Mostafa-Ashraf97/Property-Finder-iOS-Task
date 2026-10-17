import Foundation
@testable import Listings
import Networking
import Testing

struct ListingsRepositoryTests {
    // MARK: Request and mapping

    @Test func requestsTheListingsEndpointAndMapsTheDocumentedContract() async throws {
        let body = try feed([listingJSON()])
        let repository = makeRepository(StubHTTPClient { endpoint in
            #expect(endpoint as? ListingsEndpoint == .listings)
            return body
        })

        let listing = try #require(try await repository.fetchListings().first)

        #expect(listing.id == "prop_001")
        #expect(listing.bedrooms == nil, "A null bedroom count represents a studio")
        #expect(listing.price == 2_575_000)
        #expect(listing.tags == [.verified, .newConstruction, .liveViewing])
        #expect(listing.images == ["first_image", "second_image"])
        #expect(listing.contactOptions == [.phone, .email, .whatsApp])
        #expect(listing.publishedAt == date("2024-11-28T00:00:00Z"))
        #expect(listing.lastContactedAt == date("2021-07-28T00:00:00Z"))
    }

    @Test func keepsANullLastContactedDateEmpty() async throws {
        let listings = try await fetch([listingJSON(["lastContactedAt": NSNull()])])

        #expect(listings.first?.lastContactedAt == nil)
    }

    @Test func dropsUnknownAndRepeatedTagsAndContactOptions() async throws {
        let listings = try await fetch([listingJSON([
            "tags": ["verified", "rooftop_pool", "verified"],
            "contactOptions": ["fax", "phone", "phone"],
        ])])

        #expect(listings.first?.tags == [.verified])
        #expect(listings.first?.contactOptions == [.phone])
    }

    // MARK: Invalid data and identity validation

    @Test func rejectsTheFeedWhenAListingIsMissingARequiredField() async {
        await #expect(throws: ListingsError.invalidData) {
            try await fetch([
                listingJSON(["id": "valid_1"]),
                listingJSON(["id": "missing_price"], removing: "price"),
                listingJSON(["id": "valid_2"]),
            ])
        }
    }

    @Test func rejectsTheFeedWhenAListingHasAnInvalidDate() async {
        await #expect(throws: ListingsError.invalidData) {
            try await fetch([listingJSON(), listingJSON(["publishedAt": "28/11/2024"])])
        }
    }

    @Test func rejectsTheFeedWhenAnArrayElementIsNotAnObject() async {
        await #expect(throws: ListingsError.invalidData) {
            try await fetch([listingJSON(), "not an object"])
        }
    }

    @Test func skipsListingsWithBlankIdentifiers() async throws {
        let listings = try await fetch([
            listingJSON(["id": "valid_1"]),
            listingJSON(["id": " "]),
            listingJSON(["id": "valid_2"]),
        ])

        #expect(listings.map(\.id) == ["valid_1", "valid_2"])
    }

    @Test func keepsTheFirstOfDuplicateIdentifiers() async throws {
        let listings = try await fetch([listingJSON(["price": 1]), listingJSON(["price": 2])])

        #expect(listings.map(\.price) == [1])
    }

    @Test func returnsAnEmptyFeedAsEmpty() async throws {
        #expect(try await fetch([]).isEmpty)
    }

    @Test func rejectsAListingWithoutAnIdentifier() async {
        await #expect(throws: ListingsError.invalidData) {
            try await fetch([listingJSON(removing: "id")])
        }
    }

    @Test func treatsAMissingEnvelopeAsInvalidData() async {
        await #expect(throws: ListingsError.invalidData) {
            try await repository { Data(#"{"items": []}"#.utf8) }.fetchListings()
        }
    }

    // MARK: Transport failures

    enum TransportFailure: CaseIterable {
        case timeout, offline, serverError, unknownURLError

        var error: any Error {
            switch self {
            case .timeout: URLError(.timedOut)
            case .offline: URLError(.notConnectedToInternet)
            case .serverError: HTTPClientError.statusCode(503)
            case .unknownURLError: URLError(.badServerResponse)
            }
        }

        var expected: ListingsError {
            switch self {
            case .timeout: .timedOut
            case .offline: .connection
            case .serverError: .serviceUnavailable
            case .unknownURLError: .unexpected
            }
        }
    }

    @Test(arguments: TransportFailure.allCases)
    func mapsTransportFailuresToDomainErrors(failure: TransportFailure) async {
        await #expect(throws: failure.expected) {
            try await repository { throw failure.error }.fetchListings()
        }
    }

    @Test func logsFailuresWithoutExposingTheirDetails() async {
        let logger = SpyLogger()
        let repository = makeRepository(StubHTTPClient { _ in throw URLError(.timedOut) }, logger: logger)

        _ = try? await repository.fetchListings()

        #expect(logger.loggedEntries.map(\.privacy) == [.private])
    }

    @Test func reportsCancelledRequestsAsCancellation() async {
        await #expect(throws: CancellationError.self) {
            try await repository { throw URLError(.cancelled) }.fetchListings()
        }
    }

    // MARK: Helpers

    private func fetch(_ listings: [Any]) async throws -> [Listing] {
        let body = try feed(listings)
        return try await repository { body }.fetchListings()
    }

    private func repository(_ respond: @escaping @Sendable () throws -> Data) -> ListingsRepository {
        makeRepository(StubHTTPClient { _ in try respond() })
    }

    /// Exercises the real remote data source and repository; only the HTTP transport is stubbed.
    private func makeRepository(_ client: StubHTTPClient, logger: SpyLogger = SpyLogger()) -> ListingsRepository {
        ListingsRepository(remoteDataSource: ListingsRemoteDataSource(client: client), logger: logger)
    }

    /// The first listing from the README contract; tests override only what they exercise.
    private func listingJSON(_ overrides: [String: Any] = [:], removing removedKey: String? = nil) -> [String: Any] {
        var listing: [String: Any] = [
            "id": "prop_001",
            "type": "Apartment",
            "deliveryYear": 2022,
            "price": 2_575_000,
            "currency": "AED",
            "priceInclusive": true,
            "location": "Laguna Tower, Lake Almas West, Jumeirah Lake Tower",
            "bedrooms": NSNull(),
            "bathrooms": 1,
            "areaSqft": 1356,
            "publishedAt": "2024-11-28T00:00:00Z",
            "lastContactedAt": "2021-07-28T00:00:00Z",
            "tags": ["verified", "new_construction", "live_viewing"],
            "images": ["first_image", "second_image"],
            "contactOptions": ["phone", "email", "whatsapp"],
        ]
        listing.merge(overrides) { $1 }
        if let removedKey {
            listing.removeValue(forKey: removedKey)
        }
        return listing
    }

    private func feed(_ listings: [Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: ["listings": listings])
    }
}

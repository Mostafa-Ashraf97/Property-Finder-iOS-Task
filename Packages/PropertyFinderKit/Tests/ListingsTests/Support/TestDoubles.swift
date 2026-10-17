import Foundation
@testable import Listings
import Logger
import Networking
import Services
import Synchronization
import XCTest

/// Answers every request with one canned result and records the ETag each request carried.
final class StubRemoteDataSource {
    private let result: Result<HTTPResponse, any Error>
    private let etags = Mutex<[String?]>([])

    init(_ result: Result<HTTPResponse, any Error>) {
        self.result = result
    }

    static func returning(_ response: HTTPResponse) -> StubRemoteDataSource {
        StubRemoteDataSource(.success(response))
    }

    static func failing(_ error: any Error) -> StubRemoteDataSource {
        StubRemoteDataSource(.failure(error))
    }

    var receivedETags: [String?] {
        etags.withLock { $0 }
    }
}

extension StubRemoteDataSource: ListingsRemoteDataSourceProtocol {
    func fetchListings(ifNoneMatch etag: String?) async throws -> HTTPResponse {
        etags.withLock { $0.append(etag) }
        return try result.get()
    }
}

final class InMemoryListingsCache {
    private let stored: Mutex<CachedListingsResponse?>

    init(_ response: CachedListingsResponse? = nil) {
        stored = Mutex(response)
    }

    var saved: CachedListingsResponse? {
        stored.withLock { $0 }
    }
}

extension InMemoryListingsCache: ListingsLocalDataSourceProtocol {
    func load() -> CachedListingsResponse? {
        saved
    }

    func save(_ response: CachedListingsResponse) {
        stored.withLock { $0 = response }
    }
}

/// Returns queued feeds in order and counts calls. A call after the queue runs out fails the test.
final class StubFetchListingsUseCase {
    private let results: Mutex<[Result<ListingsFeed, ListingsError>]>
    private let calls = Mutex(0)

    init(_ results: [Result<ListingsFeed, ListingsError>]) {
        self.results = Mutex(results)
    }

    var callCount: Int {
        calls.withLock { $0 }
    }
}

extension StubFetchListingsUseCase: FetchListingsUseCaseProtocol {
    func execute() async throws -> ListingsFeed {
        calls.withLock { $0 += 1 }
        guard let next = results.withLock({ $0.isEmpty ? nil : $0.removeFirst() }) else {
            XCTFail("Fetched more often than the test queued feeds for")
            throw ListingsError.unexpected
        }
        return try next.get()
    }
}

@MainActor
final class InMemoryFavouritesRepository {
    private(set) var ids: Set<String>
    private(set) var saveCount = 0

    init(ids: Set<String> = []) {
        self.ids = ids
    }
}

extension InMemoryFavouritesRepository: FavouritesRepositoryProtocol {
    func loadIDs() -> Set<String> {
        ids
    }

    func saveIDs(_ ids: Set<String>) {
        self.ids = ids
        saveCount += 1
    }
}

/// Lets a test decide when the network comes and goes.
final class StubNetworkMonitor {
    private let stream: AsyncStream<Bool>
    private let continuation: AsyncStream<Bool>.Continuation

    init() {
        (stream, continuation) = AsyncStream.makeStream()
    }

    func send(_ isOnline: Bool) {
        continuation.yield(isOnline)
    }

    func finish() {
        continuation.finish()
    }

    /// Reports going offline, then coming back online, then ends the stream.
    func reconnect() {
        send(false)
        send(true)
        finish()
    }
}

extension StubNetworkMonitor: NetworkMonitorProtocol {
    func updates() -> AsyncStream<Bool> {
        stream
    }
}

struct StubFeatureFlags {
    let enabled: Set<FeatureFlagKeys>
}

extension StubFeatureFlags: FeatureFlagProviderProtocol {
    func isEnabled(_ key: FeatureFlagKeys, defaultValue _: Bool) -> Bool {
        enabled.contains(key)
    }
}

final class SpyLogger {
    struct Entry: Equatable {
        let message: String
        let details: String?
    }

    private let entries = Mutex<[Entry]>([])

    var loggedEntries: [Entry] {
        entries.withLock { $0 }
    }

    private func record(_ message: String, _ details: String?) {
        entries.withLock { $0.append(Entry(message: message, details: details)) }
    }
}

extension SpyLogger: LoggerProtocol {
    func debug(_ message: String, private details: String?) {
        record(message, details)
    }

    func info(_ message: String, private details: String?) {
        record(message, details)
    }

    func error(_ message: String, private details: String?) {
        record(message, details)
    }
}

final class SpyAnalytics {
    private let events = Mutex<[AnalyticsEvent]>([])

    var trackedEvents: [AnalyticsEvent] {
        events.withLock { $0 }
    }
}

extension SpyAnalytics: AnalyticsTrackerProtocol {
    func track(_ event: AnalyticsEvent) {
        events.withLock { $0.append(event) }
    }
}

/// A view model over stubs, with the real query and favourites use cases.
@MainActor
func makeListingsViewModel(
    feeds: [Result<ListingsFeed, ListingsError>],
    favourites: Set<String> = [],
    network: StubNetworkMonitor = StubNetworkMonitor(),
    flags: StubFeatureFlags = StubFeatureFlags(enabled: [.listingsFiltersEnabled, .listingsSortEnabled]),
    logger: SpyLogger = SpyLogger()
) -> (ListingsViewModel, StubFetchListingsUseCase) {
    let fetch = StubFetchListingsUseCase(feeds)
    let repository = InMemoryFavouritesRepository(ids: favourites)
    let viewModel = ListingsViewModel(
        fetchListingsUseCase: fetch,
        loadFavouritesUseCase: LoadFavouritesUseCase(repository: repository),
        toggleFavouriteUseCase: ToggleFavouriteUseCase(repository: repository),
        queryListingsUseCase: QueryListingsUseCase(),
        networkMonitor: network,
        featureFlags: flags,
        logger: logger
    )
    return (viewModel, fetch)
}

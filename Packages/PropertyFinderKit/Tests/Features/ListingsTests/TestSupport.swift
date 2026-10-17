import Foundation
@testable import Listings
import Logger
import Networking
import Synchronization

// MARK: Fixtures

func date(_ iso8601: String) -> Date {
    // Fixture literals are valid by construction.
    ISO8601DateFormatter().date(from: iso8601) ?? .distantPast
}

// MARK: Test doubles

struct StubHTTPClient {
    let handler: @Sendable (any Endpoint) throws -> Data
}

extension StubHTTPClient: HTTPClientProtocol {
    func data(for endpoint: any Endpoint) async throws -> Data {
        try handler(endpoint)
    }
}

/// Records messages so tests can check what was logged and how.
final class SpyLogger {
    struct Entry: Equatable {
        let message: String
        let privacy: LogPrivacy
    }

    private let entries = Mutex<[Entry]>([])

    var loggedEntries: [Entry] {
        entries.withLock { $0 }
    }

    private func record(_ message: String, _ privacy: LogPrivacy) {
        entries.withLock { $0.append(Entry(message: message, privacy: privacy)) }
    }
}

extension SpyLogger: LoggerProtocol {
    func debug(_ message: String, privacy: LogPrivacy) {
        record(message, privacy)
    }

    func info(_ message: String, privacy: LogPrivacy) {
        record(message, privacy)
    }

    func error(_ message: String, privacy: LogPrivacy) {
        record(message, privacy)
    }
}

/// Returns queued results in order, one per call.
final class SequencedFetchListings {
    private let results: Mutex<[Result<[Listing], ListingsError>]>

    init(_ results: [Result<[Listing], ListingsError>]) {
        self.results = Mutex(results)
    }
}

extension SequencedFetchListings: FetchListingsUseCaseProtocol {
    func execute() async throws -> [Listing] {
        try results.withLock { $0.removeFirst() }.get()
    }
}

/// Suspends every call until the test completes it, to exercise overlapping and cancelled requests.
final class ControlledFetchListings {
    private let pending = Mutex<[CheckedContinuation<[Listing], any Error>]>([])

    var callCount: Int {
        pending.withLock { $0.count }
    }

    func complete(call index: Int, with result: Result<[Listing], any Error>) {
        pending.withLock { $0[index] }.resume(with: result)
    }
}

extension ControlledFetchListings: FetchListingsUseCaseProtocol {
    func execute() async throws -> [Listing] {
        try await withCheckedThrowingContinuation { continuation in
            pending.withLock { $0.append(continuation) }
        }
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

/// Polls briefly so tests can wait for work that hops between executors.
@MainActor
func waitUntil(_ condition: () -> Bool) async throws {
    for _ in 0 ..< 200 {
        if condition() {
            return
        }
        try await Task.sleep(for: .milliseconds(5))
    }
}

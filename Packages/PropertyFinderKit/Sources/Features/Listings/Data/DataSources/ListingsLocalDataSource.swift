import Foundation

/// The last listings response the server sent, kept so listings can be shown offline.
struct CachedListingsResponse: Codable, Equatable, Sendable {
    let body: Data
    let etag: String?
}

protocol ListingsLocalDataSourceProtocol: Sendable {
    func load() -> CachedListingsResponse?
    func save(_ response: CachedListingsResponse)
}

/// Keeps the cached response in one file in Caches, which the system may clear when storage runs low.
struct ListingsLocalDataSource {
    private let fileURL: URL

    init(fileURL: URL = .cachesDirectory.appending(path: "listings-response.json")) {
        self.fileURL = fileURL
    }
}

extension ListingsLocalDataSource: ListingsLocalDataSourceProtocol {
    func load() -> CachedListingsResponse? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(CachedListingsResponse.self, from: data)
    }

    func save(_ response: CachedListingsResponse) {
        guard let data = try? JSONEncoder().encode(response) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

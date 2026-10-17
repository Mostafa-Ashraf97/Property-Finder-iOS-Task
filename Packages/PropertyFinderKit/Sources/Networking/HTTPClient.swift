import Foundation

/// A successful HTTP response: a 2xx status with its body, or 304 Not Modified with an empty body.
public struct HTTPResponse: Sendable {
    public let statusCode: Int
    public let data: Data
    public let etag: String?

    public init(statusCode: Int, data: Data, etag: String? = nil) {
        self.statusCode = statusCode
        self.data = data
        self.etag = etag
    }

    public var isNotModified: Bool {
        statusCode == 304
    }
}

public protocol HTTPClientProtocol: Sendable {
    /// Sends the endpoint's request. With an `etag`, the server answers 304 Not Modified when its version still matches.
    func response(for endpoint: any Endpoint, ifNoneMatch etag: String?) async throws -> HTTPResponse
}

/// Decodes API response bodies, reading ISO 8601 dates.
public enum JSONResponse {
    public static func decode<Response: Decodable>(_: Response.Type, from data: Data) throws -> Response {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Response.self, from: data)
    }
}

public enum HTTPClientError: Error {
    case invalidResponse
    case statusCode(Int)
}

public struct URLSessionHTTPClient {
    private let session: URLSession

    public init(session: URLSession) {
        self.session = session
    }
}

extension URLSessionHTTPClient: HTTPClientProtocol {
    public func response(for endpoint: any Endpoint, ifNoneMatch etag: String?) async throws -> HTTPResponse {
        var request = try endpoint.makeRequest()
        if let etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
            request.cachePolicy = .reloadIgnoringLocalCacheData
        }
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()

        guard let response = response as? HTTPURLResponse else {
            throw HTTPClientError.invalidResponse
        }
        guard (200 ..< 300).contains(response.statusCode) || response.statusCode == 304 else {
            throw HTTPClientError.statusCode(response.statusCode)
        }
        return HTTPResponse(statusCode: response.statusCode, data: data, etag: response.value(forHTTPHeaderField: "ETag"))
    }
}

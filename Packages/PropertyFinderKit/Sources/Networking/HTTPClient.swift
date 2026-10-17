import Foundation

public protocol HTTPClientProtocol: Sendable {
    func data(for endpoint: any Endpoint) async throws -> Data
}

public extension HTTPClientProtocol {
    func request<Response: Decodable>(_ endpoint: any Endpoint, as _: Response.Type = Response.self) async throws -> Response {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try await decoder.decode(Response.self, from: data(for: endpoint))
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
    public func data(for endpoint: any Endpoint) async throws -> Data {
        let (data, response) = try await session.data(for: endpoint.makeRequest())
        try Task.checkCancellation()

        guard let response = response as? HTTPURLResponse else {
            throw HTTPClientError.invalidResponse
        }
        guard (200 ..< 300).contains(response.statusCode) else {
            throw HTTPClientError.statusCode(response.statusCode)
        }
        return data
    }
}

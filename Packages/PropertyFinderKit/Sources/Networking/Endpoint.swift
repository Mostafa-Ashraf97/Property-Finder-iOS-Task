import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public protocol Endpoint: Sendable {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
}

public extension Endpoint {
    var baseURL: String {
        "https://simplejsoncms.com"
    }

    var headers: [String: String] {
        [:]
    }

    func makeRequest() throws -> URLRequest {
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url.appending(path: path))
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }
}

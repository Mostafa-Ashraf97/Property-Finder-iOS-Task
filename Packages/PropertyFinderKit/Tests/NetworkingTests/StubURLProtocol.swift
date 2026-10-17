import Foundation
import Synchronization

/// Answers requests in-process with a canned response, so tests never reach the network.
final class StubURLProtocol: URLProtocol {
    private struct Reply {
        let statusCode: Int
        let headers: [String: String]
        let body: Data
    }

    private static let reply = Mutex<Reply?>(nil)
    private static let receivedRequests = Mutex<[URLRequest]>([])

    static var requests: [URLRequest] {
        receivedRequests.withLock { $0 }
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    static func respond(statusCode: Int, headers: [String: String] = [:], body: Data = Data()) {
        reply.withLock { $0 = Reply(statusCode: statusCode, headers: headers, body: body) }
    }

    static func reset() {
        reply.withLock { $0 = nil }
        receivedRequests.withLock { $0 = [] }
    }

    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.receivedRequests.withLock { $0.append(request) }
        guard let reply = Self.reply.withLock({ $0 }),
              let url = request.url,
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: reply.statusCode,
                  httpVersion: nil,
                  headerFields: reply.headers
              )
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: reply.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

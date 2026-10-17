import Foundation
import Networking
import XCTest

final class URLSessionHTTPClientTests: XCTestCase {
    private struct TestEndpoint: Endpoint {
        let baseURL = "https://api.test"
        let path = "/listings"
        let method = HTTPMethod.get
    }

    private let client = URLSessionHTTPClient(session: StubURLProtocol.makeSession())

    override func tearDown() {
        StubURLProtocol.reset()
        super.tearDown()
    }

    func test_response_whenTheServerReturns200_returnsTheBodyAndETag() async throws {
        // Given
        StubURLProtocol.respond(statusCode: 200, headers: ["ETag": "\"v1\""], body: Data("{}".utf8))

        // When
        let response = try await client.response(for: TestEndpoint(), ifNoneMatch: nil)

        // Then
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.data, Data("{}".utf8))
        XCTAssertEqual(response.etag, "\"v1\"")
        XCTAssertFalse(response.isNotModified)
    }

    func test_response_withAnETag_sendsItAsIfNoneMatch() async throws {
        // Given
        StubURLProtocol.respond(statusCode: 304)

        // When
        _ = try await client.response(for: TestEndpoint(), ifNoneMatch: "\"v1\"")

        // Then
        XCTAssertEqual(StubURLProtocol.requests.last?.value(forHTTPHeaderField: "If-None-Match"), "\"v1\"")
    }

    func test_response_withoutAnETag_sendsNoIfNoneMatch() async throws {
        // Given
        StubURLProtocol.respond(statusCode: 200)

        // When
        _ = try await client.response(for: TestEndpoint(), ifNoneMatch: nil)

        // Then
        XCTAssertNil(StubURLProtocol.requests.last?.value(forHTTPHeaderField: "If-None-Match"))
    }

    func test_response_whenTheServerReturns304_returnsNotModified() async throws {
        // Given
        StubURLProtocol.respond(statusCode: 304, headers: ["ETag": "\"v1\""])

        // When
        let response = try await client.response(for: TestEndpoint(), ifNoneMatch: "\"v1\"")

        // Then
        XCTAssertTrue(response.isNotModified)
        XCTAssertTrue(response.data.isEmpty)
    }

    func test_response_whenTheServerReturns500_throwsTheStatusCode() async {
        // Given
        StubURLProtocol.respond(statusCode: 500)

        // When
        var thrownError: (any Error)?
        do {
            _ = try await client.response(for: TestEndpoint(), ifNoneMatch: nil)
        } catch {
            thrownError = error
        }

        // Then
        guard case let HTTPClientError.statusCode(code)? = thrownError as? HTTPClientError else {
            return XCTFail("Expected a status-code error, got \(String(describing: thrownError))")
        }
        XCTAssertEqual(code, 500)
    }

    func test_decode_withAnISO8601Date_readsTheDate() throws {
        // Given
        struct Payload: Decodable {
            let publishedAt: Date
        }
        let body = Data(#"{"publishedAt": "2024-11-28T00:00:00Z"}"#.utf8)

        // When
        let payload = try JSONResponse.decode(Payload.self, from: body)

        // Then
        XCTAssertEqual(payload.publishedAt, Date(timeIntervalSince1970: 1_732_752_000))
    }
}

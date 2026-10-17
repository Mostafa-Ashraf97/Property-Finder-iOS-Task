import Foundation
import Networking
import XCTest

final class EndpointTests: XCTestCase {
    private struct CustomEndpoint: Endpoint {
        var baseURL = "https://api.test"
        let path = "/v1/items"
        let method = HTTPMethod.post
        var headers = ["X-Trace": "abc"]
    }

    private struct DefaultEndpoint: Endpoint {
        let path = "/api/listings"
        let method = HTTPMethod.get
    }

    func test_makeRequest_usesTheEndpointsURLMethodAndHeaders() throws {
        // Given
        let endpoint = CustomEndpoint()

        // When
        let request = try endpoint.makeRequest()

        // Then
        XCTAssertEqual(request.url?.absoluteString, "https://api.test/v1/items")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Trace"), "abc")
    }

    func test_makeRequest_withoutACustomBaseURL_usesTheSharedHost() throws {
        // Given
        let endpoint = DefaultEndpoint()

        // When
        let request = try endpoint.makeRequest()

        // Then
        XCTAssertEqual(request.url?.absoluteString, "https://simplejsoncms.com/api/listings")
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func test_makeRequest_withAMalformedBaseURL_throwsBadURL() {
        // Given
        let endpoint = CustomEndpoint(baseURL: "")

        // When / Then
        XCTAssertThrowsError(try endpoint.makeRequest()) { error in
            XCTAssertEqual((error as? URLError)?.code, .badURL)
        }
    }
}

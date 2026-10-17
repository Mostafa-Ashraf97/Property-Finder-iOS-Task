@testable import Listings
import XCTest

final class ListingsEndpointTests: XCTestCase {
    func test_listings_buildsTheDocumentedRequest() throws {
        // Given
        let endpoint = ListingsEndpoint.listings

        // When
        let request = try endpoint.makeRequest()

        // Then
        XCTAssertEqual(request.url?.absoluteString, "https://simplejsoncms.com/api/m6nfoc4jlw")
        XCTAssertEqual(request.httpMethod, "GET")
    }
}

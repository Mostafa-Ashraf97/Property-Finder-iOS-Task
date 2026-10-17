import Foundation
import Networking
import Testing

struct EndpointTests {
    private struct TestEndpoint: Endpoint {
        var path = "/api/listings"
        var method = HTTPMethod.get
    }

    private struct OtherHostEndpoint: Endpoint {
        var baseURL: String
        var path = "/v2/search"
        var method = HTTPMethod.post
        var headers = ["Authorization": "Bearer token"]
    }

    @Test func usesTheSharedBaseURLAndAlwaysAcceptsJSON() throws {
        let request = try TestEndpoint().makeRequest()

        #expect(request.url?.absoluteString == "https://simplejsoncms.com/api/listings")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func addsAnEndpointsOwnHostAndHeadersWithoutDroppingAccept() throws {
        let request = try OtherHostEndpoint(baseURL: "https://example.com").makeRequest()

        #expect(request.url?.absoluteString == "https://example.com/v2/search")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test(arguments: [HTTPMethod.get, .post, .put, .delete])
    func usesTheEndpointsOwnMethod(method: HTTPMethod) throws {
        #expect(try TestEndpoint(method: method).makeRequest().httpMethod == method.rawValue)
    }

    @Test func rejectsAMalformedBaseURLInsteadOfCrashing() {
        #expect(throws: URLError.self) {
            try OtherHostEndpoint(baseURL: "").makeRequest()
        }
    }
}

struct HTTPClientDecodingTests {
    fileprivate struct StubClient {
        let body: Data
    }

    private struct Payload: Decodable, Equatable {
        let name: String
        let publishedAt: Date
    }

    @Test func decodesTheResponseIncludingISO8601Dates() async throws {
        let client = StubClient(body: Data(#"{"name": "Marina", "publishedAt": "2024-11-28T00:00:00Z"}"#.utf8))

        let payload: Payload = try await client.request(EndpointTests.Probe())

        #expect(payload == Payload(name: "Marina", publishedAt: Date(timeIntervalSince1970: 1_732_752_000)))
    }
}

extension EndpointTests {
    struct Probe: Endpoint {
        let path = "/probe"
        let method = HTTPMethod.get
    }
}

extension HTTPClientDecodingTests.StubClient: HTTPClientProtocol {
    func data(for _: any Endpoint) async throws -> Data {
        body
    }
}

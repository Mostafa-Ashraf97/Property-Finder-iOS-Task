import Networking

enum ListingsEndpoint {
    case listings
}

extension ListingsEndpoint: Endpoint {
    var path: String {
        switch self {
        case .listings: "/api/m6nfoc4jlw"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .listings: .get
        }
    }
}

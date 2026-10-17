extension ListingsError {
    var message: String {
        switch self {
        case .connection: "Check your internet connection and try again."
        case .timedOut: "The request took too long. Please try again."
        case .serviceUnavailable: "The property service is currently unavailable. Please try again."
        case .invalidData: "We couldn't read the property information. Please try again."
        case .unexpected: "Something went wrong while loading properties. Please try again."
        }
    }
}

/// Why listings could not be loaded, in terms the feature cares about. The data layer maps
/// transport and decoding failures to these cases; presentation turns them into messages.
enum ListingsError: Error, Equatable {
    case connection
    case timedOut
    case serviceUnavailable
    case invalidData
    case unexpected
}

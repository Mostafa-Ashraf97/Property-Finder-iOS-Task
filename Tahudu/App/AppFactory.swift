import Foundation
import Listings
import Logger
import Networking
import Settings

/// The composition root: owns the app's shared services and creates each feature's screens from them.
struct AppFactory {
    private let httpClient: any HTTPClientProtocol = URLSessionHTTPClient(session: URLSession(configuration: .default))
    private let defaults: UserDefaults = .standard
    private let logger: LoggerProtocol = AppLogger()

    func makeListingsView() -> ListingsView {
        let listingFactory = ListingsFactory(httpClient: httpClient, defaults: defaults, logger: logger)
        let view = listingFactory.makeListingsView()

        return view
    }

    func makeSettingsView() -> SettingsView {
        SettingsView()
    }
}

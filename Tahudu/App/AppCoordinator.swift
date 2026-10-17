import Listings
import Observation
import Settings
import SwiftUI

enum AppTab: CaseIterable {
    case listings
    case settings

    var title: String {
        switch self {
        case .listings: "Search"
        case .settings: "My Account"
        }
    }

    var systemImage: String {
        switch self {
        case .listings: "magnifyingglass"
        case .settings: "person"
        }
    }
}

/// Owns app-level navigation. Each tab's screen is built once, so re-rendering the tab view never rebuilds a feature.
@Observable
final class AppCoordinator {
    var selectedTab: AppTab
    @ObservationIgnored private let listingsScreen: ListingsView
    @ObservationIgnored private let settingsScreen: SettingsView

    init(factory: AppFactory, initialTab: AppTab = .listings) {
        listingsScreen = factory.makeListingsView()
        settingsScreen = factory.makeSettingsView()
        selectedTab = initialTab
    }

    @ViewBuilder
    func screen(for tab: AppTab) -> some View {
        switch tab {
        case .listings:
            listingsScreen
        case .settings:
            settingsScreen
                .ignoresSafeArea()
        }
    }
}

import Observation
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

/// Owns app-level navigation and asks the factory for each destination's screen.
@Observable
final class AppCoordinator {
    var selectedTab: AppTab
    @ObservationIgnored private let factory: AppFactory

    init(factory: AppFactory, initialTab: AppTab = .listings) {
        self.factory = factory
        selectedTab = initialTab
    }

    @ViewBuilder
    func makeScreen(for tab: AppTab) -> some View {
        switch tab {
        case .listings:
            factory.makeListingsView()
        case .settings:
            factory.makeSettingsView()
                .ignoresSafeArea()
        }
    }
}

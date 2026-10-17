import Foundation
@testable import Listings
import Services
import XCTest

@MainActor
final class ListingsViewModelAnalyticsDecoratorTests: XCTestCase {
    func test_toggleFavourite_tracksTheTapAndForwardsIt() async {
        // Given
        let (viewModel, _) = makeListingsViewModel(feeds: [.success(.fresh([.fixture(id: "a")]))])
        let analytics = SpyAnalytics()
        let decorator = ListingsViewModelAnalyticsDecorator(decoratee: viewModel, tracker: analytics)
        await decorator.load()

        // When
        decorator.toggleFavourite(id: "a")

        // Then
        XCTAssertEqual(analytics.trackedEvents, [ListingsAnalyticsEvent.favouriteTapped()])
        guard case let .results(cards) = decorator.state else { return XCTFail("Expected results") }
        XCTAssertEqual(cards.first?.isFavourite, true)
    }

    func test_contact_tracksTheTypeWithoutTheListingID() {
        // Given
        let (viewModel, _) = makeListingsViewModel(feeds: [])
        let analytics = SpyAnalytics()
        let decorator = ListingsViewModelAnalyticsDecorator(decoratee: viewModel, tracker: analytics)

        // When
        decorator.contact(.whatsApp, listingID: "prop_001")

        // Then
        XCTAssertEqual(analytics.trackedEvents, [ListingsAnalyticsEvent.contactTapped(type: "whatsapp")])
        XCTAssertFalse(analytics.trackedEvents.contains { $0.parameters.values.contains("prop_001") })
    }

    func test_criteria_forwardsChangesWithoutTrackingThem() {
        // Given
        let (viewModel, _) = makeListingsViewModel(feeds: [])
        let analytics = SpyAnalytics()
        let decorator = ListingsViewModelAnalyticsDecorator(decoratee: viewModel, tracker: analytics)

        // When
        decorator.criteria.text = "marina"

        // Then
        XCTAssertEqual(viewModel.criteria.text, "marina")
        XCTAssertTrue(analytics.trackedEvents.isEmpty)
    }
}

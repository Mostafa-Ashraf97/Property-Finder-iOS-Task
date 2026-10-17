//
//  TahuduTests.swift
//  TahuduTests
//

@testable import Tahudu
import Testing

@MainActor
struct AppCoordinatorTests {
    @Test func startsOnListings() {
        #expect(makeCoordinator().selectedTab == .listings)
    }

    @Test func tracksTheSelectedTab() {
        let coordinator = makeCoordinator()

        coordinator.selectedTab = .settings

        #expect(coordinator.selectedTab == .settings)
    }

    @Test func listsTabsInDisplayOrder() {
        #expect(AppTab.allCases.map(\.title) == ["Search", "My Account"])
    }

    private func makeCoordinator() -> AppCoordinator {
        AppCoordinator(factory: AppFactory())
    }
}

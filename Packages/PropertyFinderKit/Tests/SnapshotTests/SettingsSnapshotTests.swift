@testable import Settings
import XCTest

@MainActor
final class SettingsSnapshotTests: XCTestCase {
    func test_settingsViewController_withDefaultValues_matchesSnapshot() throws {
        // Given
        let screen = SettingsViewController(style: .insetGrouped)

        // When / Then
        try assertSnapshot(of: screen, named: "screen")
    }
}

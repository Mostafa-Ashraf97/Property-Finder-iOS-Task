@testable import Settings
import UIKit
import XCTest

@MainActor
final class SettingsViewControllerTests: XCTestCase {
    private struct Row: Equatable {
        let title: String?
        let value: String?
    }

    func test_viewDidLoad_setsTheMyAccountTitle() throws {
        // When
        let (controller, _) = try makeSettings()

        // Then
        XCTAssertEqual(controller.title, "My Account")
    }

    func test_cells_showTheRowsInOrderWithTheirValues() throws {
        // When
        let rows = try cells().map { section in
            section.map { cell in
                let content = cell.contentConfiguration as? UIListContentConfiguration
                return Row(title: content?.text, value: content?.secondaryText)
            }
        }

        // Then
        XCTAssertEqual(rows, [
            [
                Row(title: "Language", value: "English"),
                Row(title: "Country", value: "United Arab Emirates"),
                Row(title: "Notifications", value: nil),
            ],
            [
                Row(title: "About", value: nil),
                Row(title: "Feedback", value: nil),
            ],
        ])
    }

    func test_cells_showTheirIconAndADisclosureIndicator() throws {
        // Given
        let symbols = ["textformat", "globe", "app.badge", "info.circle", "text.bubble"]

        // When
        let cells = try cells().flatMap(\.self)

        // Then
        XCTAssertEqual(cells.count, symbols.count)
        for (cell, symbol) in zip(cells, symbols) {
            let content = try XCTUnwrap(cell.contentConfiguration as? UIListContentConfiguration)
            XCTAssertEqual(content.image, UIImage(systemName: symbol))
            XCTAssertEqual(cell.accessoryType, .disclosureIndicator)
        }
    }

    func test_didSelectRow_deselectsTheRow() throws {
        // Given
        let (controller, tableView) = try makeSettings()
        let indexPath = IndexPath(row: 1, section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)

        // When
        controller.tableView(tableView, didSelectRowAt: indexPath)

        // Then
        XCTAssertNil(tableView.indexPathForSelectedRow)
    }

    private func makeSettings() throws -> (SettingsViewController, UITableView) {
        let controller = SettingsViewController(style: .insetGrouped)
        controller.loadViewIfNeeded()
        return try (controller, XCTUnwrap(controller.viewIfLoaded as? UITableView))
    }

    /// Every cell, grouped by section, as the table's data source provides them.
    private func cells() throws -> [[UITableViewCell]] {
        let (controller, tableView) = try makeSettings()
        return (0 ..< controller.numberOfSections(in: tableView)).map { section in
            (0 ..< controller.tableView(tableView, numberOfRowsInSection: section)).map { row in
                controller.tableView(tableView, cellForRowAt: IndexPath(row: row, section: section))
            }
        }
    }
}

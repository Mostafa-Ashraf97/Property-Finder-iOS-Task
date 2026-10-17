@testable import Settings
import UIKit
import XCTest

@MainActor
final class SettingsViewControllerTests: XCTestCase {
    func testScreenTitle() {
        let controller = makeController()

        XCTAssertEqual(controller.title, "My Account")
    }

    func testSectionAndRowCounts() throws {
        let controller = makeController()
        let tableView = try XCTUnwrap(controller.tableView)

        XCTAssertEqual(controller.numberOfSections(in: tableView), 2)
        XCTAssertEqual(controller.tableView(tableView, numberOfRowsInSection: 0), 3)
        XCTAssertEqual(controller.tableView(tableView, numberOfRowsInSection: 1), 2)
    }

    func testRowContent() throws {
        let controller = makeController()
        let tableView = try XCTUnwrap(controller.tableView)
        let expectedRows: [[(title: String, value: String?, symbol: String)]] = [
            [
                ("Language", "English", "textformat"),
                ("Country", "United Arab Emirates", "globe"),
                ("Notifications", nil, "app.badge"),
            ],
            [
                ("About", nil, "info.circle"),
                ("Feedback", nil, "text.bubble"),
            ],
        ]

        for (section, rows) in expectedRows.enumerated() {
            for (row, expected) in rows.enumerated() {
                let indexPath = IndexPath(row: row, section: section)
                let cell = controller.tableView(tableView, cellForRowAt: indexPath)
                let content = try XCTUnwrap(cell.contentConfiguration as? UIListContentConfiguration)

                XCTAssertEqual(content.text, expected.title)
                XCTAssertEqual(content.secondaryText, expected.value)
                XCTAssertNotNil(content.image)
                XCTAssertEqual(content.image, UIImage(systemName: expected.symbol))
                XCTAssertEqual(cell.accessoryType, .disclosureIndicator)
            }
        }
    }

    func testSelectingARowDeselectsIt() throws {
        let controller = makeController()
        let tableView = try XCTUnwrap(controller.tableView)
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        XCTAssertEqual(tableView.indexPathForSelectedRow, indexPath)

        controller.tableView(tableView, didSelectRowAt: indexPath)

        XCTAssertNil(tableView.indexPathForSelectedRow)
    }

    private func makeController() -> SettingsViewController {
        let controller = SettingsViewController(style: .insetGrouped)
        controller.loadViewIfNeeded()
        return controller
    }
}

import UIKit

final class SettingsViewController: UITableViewController {
    private static let cellIdentifier = "SettingsCell"
    private lazy var sections = makeSections()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Account"
    }

    override func numberOfSections(in _: UITableView) -> Int {
        sections.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = row(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier)
            ?? UITableViewCell(style: .default, reuseIdentifier: Self.cellIdentifier)

        var content = UIListContentConfiguration.valueCell()
        content.image = UIImage(systemName: row.systemImage)
        content.text = row.title
        content.secondaryText = row.value
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityIdentifier = row.id
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        row(at: indexPath).action()
    }

    private func row(at indexPath: IndexPath) -> SettingsRow {
        sections[indexPath.section].rows[indexPath.row]
    }

    /// The rows in display order. They live here because their actions call the private placeholders below.
    private func makeSections() -> [SettingsSection] {
        [
            SettingsSection(rows: [
                SettingsRow(
                    id: "settings.language",
                    title: "Language",
                    systemImage: "textformat",
                    value: "English"
                ) { [weak self] in self?.openSystemSettings() },
                SettingsRow(
                    id: "settings.country",
                    title: "Country",
                    systemImage: "globe",
                    value: "United Arab Emirates"
                ) { [weak self] in self?.showCountrySelectionScreen() },
                SettingsRow(
                    id: "settings.notifications",
                    title: "Notifications",
                    systemImage: "app.badge"
                ) { [weak self] in self?.showNotificationScreen() },
            ]),
            SettingsSection(rows: [
                SettingsRow(
                    id: "settings.about",
                    title: "About",
                    systemImage: "info.circle"
                ) { [weak self] in self?.showAboutScreen() },
                SettingsRow(
                    id: "settings.feedback",
                    title: "Feedback",
                    systemImage: "text.bubble"
                ) { [weak self] in self?.showFeedbackScreen() },
            ]),
        ]
    }
}

/// NO NEED TO TUOCH THIS!!!
extension SettingsViewController {
    private func openSystemSettings() {
        print(#function)
    }

    private func showCountrySelectionScreen() {
        print(#function)
    }

    private func showNotificationScreen() {
        print(#function)
    }

    private func showAboutScreen() {
        print(#function)
    }

    private func showFeedbackScreen() {
        print(#function)
    }
}

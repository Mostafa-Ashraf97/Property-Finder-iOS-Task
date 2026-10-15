// 
//  SettingsViewController.swift
//  Tahudu
//

import Foundation
import UIKit

class SettingsViewController: UITableViewController {
    override func loadView() {
        super.loadView()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .systemGroupedBackground
        tableView.tableFooterView = UIView()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
    }

    override func numberOfSections(in _: UITableView) -> Int {
        return 2
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 3 : 2
    }

    override func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
                cell.accessibilityIdentifier = "SettingsCell_language"
                cell.backgroundColor = .systemBackground
                cell.selectionStyle = .default
                cell.accessoryType = .disclosureIndicator
                cell.imageView?.image = UIImage(systemName: "textformat")
                cell.textLabel?.text = "Language"
                cell.textLabel?.textColor = .label
                cell.textLabel?.textAlignment = .natural
                cell.detailTextLabel?.text = Locale.current.localizedString(forLanguageCode: Bundle.main.preferredLocalizations.first!)
                cell.detailTextLabel?.textColor = .secondaryLabel
                return cell
            } else if indexPath.row == 1 {
                let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
                cell.accessibilityIdentifier = "SettingsCell_country"
                cell.backgroundColor = .systemBackground
                cell.selectionStyle = .default
                cell.accessoryType = .disclosureIndicator
                cell.imageView?.image = UIImage(systemName: "globe")
                cell.textLabel?.text = "Country"
                cell.textLabel?.textColor = .label
                cell.textLabel?.textAlignment = .natural
                cell.detailTextLabel?.text = "United Arab Emirates"
                cell.detailTextLabel?.textColor = .secondaryLabel
                return cell
            } else if indexPath.row == 2 {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.accessibilityIdentifier = "SettingsCell_notifications"
                cell.backgroundColor = .systemBackground
                cell.selectionStyle = .default
                cell.accessoryType = .disclosureIndicator
                cell.imageView?.image = UIImage(systemName: "app.badge")
                cell.textLabel?.text = "Notifications"
                cell.textLabel?.textColor = .label
                cell.textLabel?.textAlignment = .natural
                return cell
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.accessibilityIdentifier = "SettingsCell_about"
                cell.backgroundColor = .systemBackground
                cell.selectionStyle = .default
                cell.accessoryType = .disclosureIndicator
                cell.imageView?.image = UIImage(systemName: "info.circle")
                cell.textLabel?.text = "About"
                cell.textLabel?.textColor = .label
                cell.textLabel?.textAlignment = .natural
                return cell
            } else if indexPath.row == 1 {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.accessibilityIdentifier = "SettnigsCell_feedback"
                cell.backgroundColor = .systemBackground
                cell.selectionStyle = .default
                cell.accessoryType = .disclosureIndicator
                cell.imageView?.image = UIImage(systemName: "text.bubble")
                cell.textLabel?.text = "Feedback"
                cell.textLabel?.textColor = .label
                cell.textLabel?.textAlignment = .natural
                return cell
            }
        }

        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 {
            if indexPath.row == 0 {
                openSystemSettings()
            } else if indexPath.row == 1 {
                showCountrySelectionScreen()
            } else if indexPath.row == 2 {
                showNotificationScreen()
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                showAboutScreen()
            } else if indexPath.row == 1 {
                showFeedbackScreen()
            }
        }
    }
}

// ===============================

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

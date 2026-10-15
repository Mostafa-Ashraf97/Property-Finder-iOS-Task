//
//  SettingsView.swift
//  Tahudu
//

import SwiftUI

struct SettingsView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let settingsViewController = SettingsViewController.init(style: .insetGrouped)
        settingsViewController.title = "My Account"

        let navigatoinController = UINavigationController(rootViewController: settingsViewController)
        navigatoinController.navigationBar.prefersLargeTitles = true
        return navigatoinController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // Nothing here
    }
}

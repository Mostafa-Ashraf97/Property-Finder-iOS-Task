import SwiftUI

/// Shows the UIKit Settings screen in a SwiftUI tab, inside the navigation controller its rows will push onto.
public struct SettingsView: UIViewControllerRepresentable {
    public init() {}

    public func makeUIViewController(context _: Context) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: SettingsViewController(style: .insetGrouped))
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.view.semanticContentAttribute = .forceLeftToRight
        return navigationController
    }

    /// The screen takes no input from SwiftUI, so there is nothing to update.
    public func updateUIViewController(_: UINavigationController, context _: Context) {}
}

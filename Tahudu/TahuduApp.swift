import SwiftUI

@main
struct TahuduApp: App {
    @State private var coordinator = AppCoordinator(factory: AppFactory())

    var body: some Scene {
        WindowGroup {
            TahuduTabView(coordinator: coordinator)
                .environment(\.locale, Locale(identifier: "en_AE"))
                .environment(\.layoutDirection, .leftToRight)
        }
    }
}

import DesignSystem
import SwiftUI

struct TahuduTabView: View {
    @Bindable var coordinator: AppCoordinator

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                    coordinator.makeScreen(for: tab)
                }
            }
        }
        .tint(.brand)
    }
}

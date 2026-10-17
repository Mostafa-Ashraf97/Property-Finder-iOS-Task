import DesignSystem
import Extensions
import SwiftUI

struct SearchHeader: View {
    let viewModel: any ListingsViewModelProtocol
    @FocusState.Binding var isSearchFocused: Bool
    @State private var text = ""

    var body: some View {
        VStack(spacing: Spacing.pt16) {
            HStack(spacing: Spacing.pt24) {
                action("slider.horizontal.3", label: "Filters")
                action("arrow.up.arrow.down", label: "Sort properties")
                Spacer(minLength: 0)
                action("star", label: "Favourites")
            }
            .buttonStyle(.borderless)
            ClearableTextField(
                label: "City, area or building",
                symbol: "magnifyingglass",
                text: $text,
                isFocused: $isSearchFocused
            )
            .textInputAutocapitalization(.words)
            .submitLabel(.search)
            .accessibilityIdentifier("search.query")
        }
        .tint(Color.accent)
        .padding(.horizontal, Spacing.pt16)
        .padding(.vertical, Spacing.pt8)
        .background(Color(uiColor: .systemBackground))
    }

    private func action(_ symbol: String, label: String) -> some View {
        Button {
            isSearchFocused = false
            viewModel.logAction("\(label) tapped")
        } label: {
            Image(systemName: symbol)
                .font(.body.weight(.light))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .foregroundStyle(Color.accent)
                .frame(minWidth: 20, minHeight: 20)
                .expandingHitArea(by: Spacing.pt12)
        }
        .accessibilityLabel(label)
    }
}

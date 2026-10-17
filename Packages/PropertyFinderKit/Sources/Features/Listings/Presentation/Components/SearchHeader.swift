import DesignSystem
import Extensions
import SwiftUI

struct SearchHeader: View {
    let viewModel: any ListingsViewModelProtocol
    @FocusState.Binding var isSearchFocused: Bool
    @State private var text = ""

    var body: some View {
        VStack(spacing: Spacing.pt16) {
            controls
            searchField
            summaryBar
        }
        .tint(Color.accent)
        .padding(.horizontal, Spacing.pt16)
        .padding(.vertical, Spacing.pt8)
        .background(Color(uiColor: .systemBackground))
    }

    private var controls: some View {
        HStack(spacing: Spacing.pt24) {
            action("slider.horizontal.3", label: "Filters")
            action("arrow.up.arrow.down", label: "Sort properties")
            Spacer(minLength: 0)
            favouritesButton
        }
        .buttonStyle(.borderless)
    }

    private var favouritesButton: some View {
        let isShowingFavourites = viewModel.criteria.favouritesOnly
        return Button {
            isSearchFocused = false
            viewModel.criteria.favouritesOnly.toggle()
        } label: {
            icon(
                isShowingFavourites ? "star.fill" : "star",
                isActive: isShowingFavourites,
                tint: isShowingFavourites ? .brand : Color.accent
            )
        }
        .accessibilityLabel("Show favourites only")
        .accessibilityValue(isShowingFavourites ? "On" : "Off")
        .accessibilityIdentifier("search.favouritesFilter")
    }

    private var searchField: some View {
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

    @ViewBuilder
    private var summaryBar: some View {
        if let summary = viewModel.resultsSummary {
            HStack(spacing: Spacing.pt4) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.brand)
                    .accessibilityHidden(true)
                Text(summary)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primaryText)
                Spacer(minLength: Spacing.pt8)
                Button("Show all") {
                    isSearchFocused = false
                    viewModel.criteria.favouritesOnly = false
                }
                .fontWeight(.semibold)
                .expandingHitArea(by: Spacing.pt12)
            }
            .font(.detail)
            .accessibilityIdentifier("search.summary")
        }
    }

    private func action(_ symbol: String, label: String) -> some View {
        Button {
            isSearchFocused = false
            viewModel.logAction("\(label) tapped")
        } label: {
            icon(symbol, isActive: false)
        }
        .accessibilityLabel(label)
    }

    private func icon(_ systemName: String, isActive: Bool, tint: Color = Color.accent) -> some View {
        Image(systemName: systemName)
            .font(.body.weight(.light))
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .foregroundStyle(tint)
            .frame(minWidth: 20, minHeight: 20)
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(tint.opacity(0.12))
                        .padding(-Spacing.pt8)
                }
            }
            .expandingHitArea(by: Spacing.pt12)
    }
}

import DesignSystem
import Extensions
import SwiftUI

struct SearchHeader: View {
    let viewModel: any ListingsViewModelProtocol
    @FocusState.Binding var isSearchFocused: Bool
    let onShowFilters: () -> Void

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
            filtersButton
            sortMenu
            Spacer(minLength: 0)
            favouritesButton
        }
        .buttonStyle(.borderless)
    }

    private var filtersButton: some View {
        let activeCount = viewModel.criteria.filters.activeCount
        return Button {
            isSearchFocused = false
            onShowFilters()
        } label: {
            icon("slider.horizontal.3", isActive: activeCount > 0)
                .overlay(alignment: .topTrailing) {
                    if activeCount > 0 {
                        Text(String(activeCount))
                            .font(.badge)
                            .foregroundStyle(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.badgeBackground, in: Circle())
                            .offset(x: Spacing.pt8, y: -Spacing.pt8)
                    }
                }
        }
    }

    private var sortMenu: some View {
        let sortOrder = Binding(
            get: { viewModel.criteria.sortOrder },
            set: { order in
                isSearchFocused = false
                viewModel.criteria.sortOrder = order
            }
        )
        return Menu {
            Picker("Sort properties", selection: sortOrder) {
                ForEach(ListingSortOrder.allCases) { order in
                    Text(order.title).tag(order)
                }
            }
        } label: {
            icon("arrow.up.arrow.down", isActive: viewModel.criteria.sortOrder != .recommended)
                .scaleEffect(x: -1)
        }
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
    }

    private var searchField: some View {
        ClearableTextField(
            label: "City, area or building",
            symbol: "magnifyingglass",
            text: Binding(
                get: { viewModel.criteria.text },
                set: { viewModel.criteria.text = $0 }
            ),
            isFocused: $isSearchFocused
        )
        .textInputAutocapitalization(.words)
        .submitLabel(.search)
    }

    @ViewBuilder
    private var summaryBar: some View {
        if let summary = viewModel.resultsSummary {
            let isShowingFavourites = viewModel.criteria.favouritesOnly
            HStack(spacing: Spacing.pt4) {
                if isShowingFavourites {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.brand)
                }
                Text(summary)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primaryText)
                Spacer(minLength: Spacing.pt8)
                Button(isShowingFavourites ? "Show all" : "Clear") {
                    isSearchFocused = false
                    if isShowingFavourites {
                        viewModel.criteria.favouritesOnly = false
                    } else {
                        viewModel.clearSearchAndFilters()
                    }
                }
                .fontWeight(.semibold)
                .expandingHitArea(by: Spacing.pt12)
            }
            .font(.detail)
        }
    }

    private func icon(_ systemName: String, isActive: Bool, tint: Color = Color.accent) -> some View {
        Image(systemName: systemName)
            .font(.body.weight(.light))
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

private extension ListingSortOrder {
    var title: String {
        switch self {
        case .recommended: "Recommended"
        case .newest: "Newest first"
        case .priceLowToHigh: "Price: low to high"
        case .priceHighToLow: "Price: high to low"
        }
    }
}

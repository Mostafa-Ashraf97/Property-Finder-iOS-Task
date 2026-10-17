import DesignSystem
import SwiftUI

public struct ListingsView: View {
    @State private var viewModel: any ListingsViewModelProtocol
    @State private var isShowingFilters = false
    @State private var retryTrigger = false
    @FocusState private var isSearchFocused: Bool

    init(viewModel: any ListingsViewModelProtocol) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ListingsContent(viewModel: viewModel, onRetry: { retryTrigger.toggle() })
            .simultaneousGesture(TapGesture().onEnded { isSearchFocused = false })
            .safeAreaInset(edge: .top, spacing: 0) {
                SearchHeader(
                    viewModel: viewModel,
                    isSearchFocused: $isSearchFocused,
                    onShowFilters: { isShowingFilters = viewModel.isFilterEnabled }
                )
            }
            .background(Color(uiColor: .systemBackground))
            .sheet(isPresented: $isShowingFilters) {
                filtersSheet
            }
            .task(id: retryTrigger) {
                await viewModel.load()
                await viewModel.observeUpdates()
            }
    }

    private var filtersSheet: some View {
        FiltersSheet(
            propertyTypes: viewModel.availablePropertyTypes,
            bedroomCounts: viewModel.availableBedroomCounts,
            selection: viewModel.criteria.filters,
            matchingCount: viewModel.matchingCount,
            onApply: { viewModel.criteria.filters = $0 }
        )
    }
}

#if DEBUG
    #Preview {
        ListingsView(viewModel: ListingsViewModelMock())
    }
#endif

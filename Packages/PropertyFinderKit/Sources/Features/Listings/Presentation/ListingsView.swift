import SwiftUI

public struct ListingsView: View {
    @State private var viewModel: any ListingsViewModelProtocol
    @State private var retryTrigger = false
    @FocusState private var isSearchFocused: Bool

    init(viewModel: any ListingsViewModelProtocol) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ListingsContent(viewModel: viewModel, onRetry: { retryTrigger.toggle() })
            .simultaneousGesture(TapGesture().onEnded { isSearchFocused = false })
            .safeAreaInset(edge: .top, spacing: 0) {
                SearchHeader(viewModel: viewModel, isSearchFocused: $isSearchFocused)
            }
            .background(Color(uiColor: .systemBackground))
            .task(id: retryTrigger) {
                await viewModel.load()
            }
    }
}

#if DEBUG
    #Preview("Results") {
        ListingsView(viewModel: ListingsViewModelMock())
    }

    #Preview("Loading") {
        ListingsView(viewModel: ListingsViewModelMock(state: .loading))
    }

    #Preview("Load failure") {
        ListingsView(viewModel: ListingsViewModelMock(state: .failed(.connection)))
    }
#endif

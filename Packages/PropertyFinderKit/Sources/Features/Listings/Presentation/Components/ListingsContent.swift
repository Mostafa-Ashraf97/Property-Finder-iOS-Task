import DesignSystem
import SwiftUI

struct ListingsContent: View {
    let viewModel: any ListingsViewModelProtocol
    let onRetry: () -> Void
    private static let topAnchor = "listings.top"

    var body: some View {
        switch viewModel.state {
        case .loading, .failed:
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        default:
            refreshableList
        }
    }

    private var refreshableList: some View {
        ScrollViewReader { scrollProxy in
            List {
                Color.clear
                    .frame(height: Spacing.pt4)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .accessibilityHidden(true)
                    .id(Self.topAnchor)

                Group {
                    if let message = viewModel.refreshMessage {
                        Text(message)
                            .font(.detail)
                            .foregroundStyle(Color.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Spacing.pt12)
                            .background(Color.noticeBackground, in: RoundedRectangle(cornerRadius: 8))
                            .accessibilityIdentifier("listings.refreshMessage")
                    }

                    content
                }
                .listRowInsets(EdgeInsets(top: Spacing.pt8, leading: Spacing.pt16, bottom: Spacing.pt8, trailing: Spacing.pt16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, 0)
            .scrollContentBackground(.hidden)
            .contentMargins(.vertical, 0, for: .scrollContent)
            .scrollDismissesKeyboard(.immediately)
            .refreshable { await viewModel.refresh() }
            .background(viewModel.criteria.favouritesOnly ? Color.accent.opacity(0.06) : .clear)
            .onChange(of: viewModel.criteria) {
                scrollProxy.scrollTo(Self.topAnchor, anchor: .top)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            loadingIndicator
        case let .failed(error):
            message(
                title: "Unable to load properties",
                text: error.message,
                systemImage: "exclamationmark.triangle",
                action: ("Retry", onRetry)
            )
        case .noListings:
            message(
                title: "No properties available",
                text: "There are no listings to show right now.",
                systemImage: "house"
            )
        case .noFavourites:
            message(
                title: "No favourites yet",
                text: "Tap the heart on a property to save it here.",
                systemImage: "heart",
                action: ("Show all properties", { viewModel.criteria.favouritesOnly = false })
            )
        case let .results(cards):
            cardList(cards)
        }
    }

    private var loadingIndicator: some View {
        ProgressView("Loading properties…")
            .font(.detail)
            .frame(maxWidth: .infinity, minHeight: 200)
    }

    private func cardList(_ cards: [ListingCardViewData]) -> some View {
        ForEach(cards) { card in
            ListingCard(
                card: card,
                onToggleFavourite: { viewModel.toggleFavourite(id: card.id) },
                onContact: { viewModel.contact($0, listingID: card.id) }
            )
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
    }

    private func message(
        title: String,
        text: String,
        systemImage: String,
        action: (title: String, perform: () -> Void)? = nil
    ) -> some View {
        VStack(spacing: Spacing.pt16) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(title)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.isHeader)
            Text(text)
                .foregroundStyle(.secondary)
            if let action {
                Button(action.title, action: action.perform)
                    .buttonStyle(.borderedProminent)
            }
        }
        .font(.detail)
        .multilineTextAlignment(.center)
        .padding(Spacing.pt24)
        .padding(.top, Spacing.pt48)
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity)
    }
}

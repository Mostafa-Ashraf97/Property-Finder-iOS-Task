import DesignSystem
import SwiftUI

struct ListingsContent: View {
    let viewModel: any ListingsViewModelProtocol
    let onRetry: () -> Void
    private static let topAnchor = "listings.top"

    var body: some View {
        switch viewModel.state {
        case .loading:
            list
                .scrollDisabled(true)
        case .failed:
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        default:
            list
                .refreshable { await viewModel.refresh() }
        }
    }

    private var list: some View {
        ScrollViewReader { scrollProxy in
            List {
                Color.clear
                    .frame(height: Spacing.pt4)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .id(Self.topAnchor)

                Group {
                    if viewModel.isShowingSavedListings {
                        Label {
                            Text("You appear to be offline. Showing saved properties.")
                        } icon: {
                            Image(systemName: "wifi.slash")
                        }
                        .accessibilityIdentifier("listings.offlineNotice")
                        .font(.detail)
                        .foregroundStyle(Color.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.pt12)
                        .background(Color.noticeBackground, in: RoundedRectangle(cornerRadius: 8))
                    }

                    if let message = viewModel.refreshMessage {
                        Text(message)
                            .accessibilityIdentifier("listings.refreshMessage")
                            .font(.detail)
                            .foregroundStyle(Color.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Spacing.pt12)
                            .background(Color.noticeBackground, in: RoundedRectangle(cornerRadius: 8))
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
            ListingsSkeleton()
        case let .failed(error):
            message(
                title: "Unable to load properties",
                text: error.message,
                systemImage: "exclamationmark.triangle",
                identifier: "listings.error",
                action: ("Retry", onRetry)
            )
        case .noListings:
            message(
                title: "No properties available",
                text: "There are no listings to show right now.",
                systemImage: "house",
                identifier: "listings.empty"
            )
        case .noFavourites:
            message(
                title: "No favourites yet",
                text: "Tap the heart on a property to save it here.",
                systemImage: "heart",
                identifier: "listings.noFavourites",
                action: ("Show all properties", { viewModel.criteria.favouritesOnly = false })
            )
        case .noMatches:
            message(
                title: viewModel.criteria.favouritesOnly ? "No matching favourites" : "No matching properties",
                text: "Try another location or clear your search and filters.",
                systemImage: "magnifyingglass",
                identifier: "listings.noMatches",
                action: ("Clear search and filters", viewModel.clearSearchAndFilters)
            )
        case let .results(cards):
            cardList(cards)
        }
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
        identifier: String,
        action: (title: String, perform: () -> Void)? = nil
    ) -> some View {
        VStack(spacing: Spacing.pt16) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .accessibilityHidden(true)
                .foregroundStyle(.secondary)
            Text(title)
                .fontWeight(.semibold)
                .accessibilityIdentifier("\(identifier).title")
            Text(text)
                .foregroundStyle(.secondary)
            if let action {
                Button(action.title, action: action.perform)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("\(identifier).action")
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

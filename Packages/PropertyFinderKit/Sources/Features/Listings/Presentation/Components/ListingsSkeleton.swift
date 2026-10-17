import SwiftUI

struct ListingsSkeleton: View {
    var body: some View {
        ForEach(0 ..< 3, id: \.self) { index in
            ListingCard(card: .placeholder(id: "skeleton-\(index)"), onToggleFavourite: {}, onContact: { _ in })
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
                .redacted(reason: .placeholder)
                .saturation(0)
                .allowsHitTesting(false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Loading properties")
                .accessibilityIdentifier("listings.loading")
                .accessibilityHidden(index != 0)
        }
    }
}

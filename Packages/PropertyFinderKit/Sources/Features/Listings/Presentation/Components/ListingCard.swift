import DesignSystem
import Extensions
import SwiftUI

struct ListingCard: View {
    let card: ListingCardViewData
    let onToggleFavourite: () -> Void
    let onContact: (ContactType) -> Void
    @Environment(\.redactionReasons) private var redactionReasons

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ListingPhotos(images: card.images)
                .overlay(alignment: .top) {
                    HStack(alignment: .top, spacing: Spacing.pt8) {
                        tags
                        Spacer(minLength: 0)
                        if !redactionReasons.contains(.placeholder) {
                            favouriteButton
                        }
                    }
                    .padding(Spacing.pt12)
                }

            details
            Divider()
            contactRow

            if let lastContacted = card.lastContacted {
                HStack(spacing: Spacing.pt4) {
                    Image(systemName: "phone.fill")
                    Text(lastContacted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.pt12)
                .padding(.vertical, Spacing.pt4)
                .background(Color.noticeBackground)
            }
        }
        .font(.detail)
        .foregroundStyle(Color.primaryText)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.cardBorder, lineWidth: 1)
                .allowsHitTesting(false)
        }
    }

    private var tags: some View {
        VStack(alignment: .leading, spacing: Spacing.pt4) {
            ForEach(card.tags, id: \.self) { tag in
                let shape = RoundedRectangle(cornerRadius: 4)
                Text(tag.title)
                    .font(.badge)
                    .foregroundStyle(tag.foregroundColor)
                    .padding(.horizontal, Spacing.pt4)
                    .frame(minHeight: 16)
                    .background(tag.backgroundColor, in: shape)
                    .background(Color(uiColor: .systemBackground), in: shape)
            }
        }
    }

    private var favouriteButton: some View {
        Button(action: onToggleFavourite) {
            Image(systemName: card.isFavourite ? "heart.fill" : "heart")
                .font(.body)
                .foregroundStyle(card.isFavourite ? Color.brand : .white)
                .frame(width: 32, height: 32)
                .background(.black.opacity(0.5), in: Circle())
                .expandingHitArea(by: Spacing.pt8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Favourite")
        .accessibilityAddTraits(card.isFavourite ? .isSelected : [])
        .accessibilityIdentifier("listing.\(card.id).favourite")
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: Spacing.pt12) {
            VStack(alignment: .leading, spacing: Spacing.pt4) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.pt8) { propertyType; delivery }
                    VStack(alignment: .leading, spacing: Spacing.pt4) { propertyType; delivery }
                }
                Text(card.price)
                    .font(.prominentValue)
                    .accessibilityIdentifier("listing.\(card.id).price")
            }
            VStack(alignment: .leading, spacing: Spacing.pt8) {
                Text(card.location)
                    .foregroundStyle(Color.secondaryText)
                    .accessibilityIdentifier("listing.\(card.id).location")
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.pt12) { facts }
                    VStack(alignment: .leading, spacing: Spacing.pt8) { facts }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.pt12)
        .padding(.top, Spacing.pt12)
        .padding(.bottom, Spacing.pt16)
    }

    private var propertyType: some View {
        Text(card.propertyType)
            .foregroundStyle(Color.secondaryText)
    }

    private var delivery: some View {
        Text(card.delivery)
            .fontWeight(.medium)
            .foregroundStyle(Color.highlightText)
            .padding(.horizontal, Spacing.pt8)
            .background(Color.highlightBackground, in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var facts: some View {
        Label(card.bedrooms, systemImage: "bed.double")
        Label(card.bathrooms, systemImage: "bathtub")
        Label(card.area, systemImage: "square.dashed")
    }

    private var contactRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.pt8) {
                published.fixedSize()
                Spacer(minLength: 0)
                contactButtons
            }
            VStack(alignment: .leading, spacing: Spacing.pt8) {
                published
                contactButtons
            }
        }
        .padding(.horizontal, Spacing.pt12)
        .padding(.vertical, Spacing.pt8)
    }

    private var published: some View {
        Text(card.published)
            .foregroundStyle(Color.secondaryText)
    }

    private var contactButtons: some View {
        HStack(spacing: Spacing.pt8) {
            ForEach(card.contactOptions, id: \.self) { type in
                Button { onContact(type) } label: {
                    type.icon
                        .font(.body)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(type.backgroundColor, in: RoundedRectangle(cornerRadius: 8))
                        .expandingHitArea(by: Spacing.pt4)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(type.actionLabel)
                .accessibilityIdentifier("listing.\(card.id).contact.\(type.rawValue)")
            }
        }
    }
}

private extension ListingTag {
    var title: String {
        switch self {
        case .verified: "VERIFIED"
        case .newConstruction: "NEW CONSTRUCTION"
        case .liveViewing: "LIVE VIEWING"
        case .furnished: "FURNISHED"
        case .priceReduced: "PRICE REDUCED"
        case .seaView: "SEA VIEW"
        case .exclusive: "EXCLUSIVE"
        case .cornerUnit: "CORNER UNIT"
        case .highFloor: "HIGH FLOOR"
        case .lowFloor: "LOW FLOOR"
        }
    }

    var foregroundColor: Color {
        switch self {
        case .verified: .white
        case .newConstruction, .exclusive: Color.highlightText
        default: Color.primaryText
        }
    }

    var backgroundColor: Color {
        switch self {
        case .verified: Color.success
        case .newConstruction, .exclusive: Color.highlightBackground
        case .liveViewing, .seaView: Color.accent.opacity(0.12)
        case .priceReduced: Color.brand.opacity(0.12)
        default: Color(uiColor: .secondarySystemBackground)
        }
    }
}

private extension ContactType {
    var actionLabel: String {
        switch self {
        case .phone: "Call agent"
        case .email: "Email agent"
        case .sms: "Send text message"
        case .whatsApp: "Contact agent on WhatsApp"
        }
    }

    var icon: Image {
        switch self {
        case .phone: Image(systemName: "phone.fill")
        case .email: Image(systemName: "envelope.fill")
        case .sms: Image(systemName: "message.fill")
        case .whatsApp: .whatsApp
        }
    }

    var backgroundColor: Color {
        self == .whatsApp ? .whatsApp : .brand
    }
}

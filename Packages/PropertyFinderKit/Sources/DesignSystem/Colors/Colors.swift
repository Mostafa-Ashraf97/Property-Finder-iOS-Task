import SwiftUI

/// Colour tokens. Light, dark and high-contrast values live in this module's asset catalog.
public extension Color {
    static let brand = Color("Brand", bundle: .module)
}

package extension Color {
    static let accent = Color("Accent", bundle: .module)

    static let primaryText = Color("PrimaryText", bundle: .module)
    static let secondaryText = Color("SecondaryText", bundle: .module)

    static let inputPlaceholder = Color("InputPlaceholder", bundle: .module)
    static let inputBorder = Color("InputBorder", bundle: .module)
    static let cardBorder = Color("CardBorder", bundle: .module)

    static let success = Color("Success", bundle: .module)
    static let highlightText = Color("HighlightText", bundle: .module)
    static let highlightBackground = Color("HighlightBackground", bundle: .module)
    static let noticeBackground = Color("NoticeBackground", bundle: .module)
    static let badgeBackground = Color("BadgeBackground", bundle: .module)

    static let whatsApp = Color("WhatsApp", bundle: .module)
}

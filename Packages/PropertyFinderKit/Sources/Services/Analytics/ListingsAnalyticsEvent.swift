package enum ListingsAnalyticsEvent {
    package static func favouriteTapped() -> AnalyticsEvent {
        AnalyticsEvent(name: "listings_favourite_tapped", parameters: [:])
    }

    package static func contactTapped(type: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "listings_contact_tapped", parameters: ["contact_type": type])
    }
}

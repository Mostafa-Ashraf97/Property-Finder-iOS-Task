/// A group of rows in the Settings table, in display order.
struct SettingsSection {
    let rows: [SettingsRow]
}

/// One Settings row: what it shows and what tapping it does.
///
/// Each row carries its own value and action, so adding a row is one new value and the table code never changes.
struct SettingsRow {
    let title: String
    let systemImage: String
    var value: String?
    let action: @MainActor () -> Void
}

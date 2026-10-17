import DesignSystem
import Extensions
import SwiftUI

struct FiltersSheet: View {
    let propertyTypes: [String]
    let bedroomCounts: [Int]
    let matchingCount: (ListingFilters) -> Int
    let onApply: (ListingFilters) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ListingFilters

    init(
        propertyTypes: [String],
        bedroomCounts: [Int],
        selection: ListingFilters,
        matchingCount: @escaping (ListingFilters) -> Int,
        onApply: @escaping (ListingFilters) -> Void
    ) {
        self.propertyTypes = propertyTypes
        self.bedroomCounts = bedroomCounts
        self.matchingCount = matchingCount
        self.onApply = onApply
        _draft = State(initialValue: selection)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(propertyTypes, id: \.self) { type in
                        let isSelected = draft.propertyTypes.contains(type)
                        Button {
                            if isSelected {
                                draft.propertyTypes.remove(type)
                            } else {
                                draft.propertyTypes.insert(type)
                            }
                        } label: {
                            HStack {
                                Text(type).foregroundStyle(Color.primaryText)
                                Spacer()
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(isSelected ? Color.accent : .secondary)
                                    .accessibilityHidden(true)
                            }
                            .contentShape(Rectangle())
                        }
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                        .accessibilityIdentifier("listings.filters.type.\(type)")
                    }
                } header: {
                    Text("Property type")
                } footer: {
                    Text("Choose one or more types. Leave all unselected to include every type.")
                }

                Section("Bedrooms") {
                    Picker("Bedrooms", selection: $draft.bedrooms) {
                        Text("Any bedrooms").tag(ListingBedroomFilter.any)
                        Text("Studio").tag(ListingBedroomFilter.studio)
                        ForEach(bedroomCounts, id: \.self) { count in
                            Text(count.counted("bedroom", plural: "bedrooms")).tag(ListingBedroomFilter.count(count))
                        }
                    }
                    .accessibilityIdentifier("listings.filters.bedrooms")
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("listings.filters.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Reset") { draft = ListingFilters() }
                        .disabled(draft.activeCount == 0)
                        .accessibilityIdentifier("listings.filters.reset")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    onApply(draft)
                    dismiss()
                } label: {
                    let count = matchingCount(draft)
                    Text("Show \(count.counted("property", plural: "properties"))")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("listings.filters.apply")
                .padding(Spacing.pt16)
                .background(.regularMaterial)
            }
        }
        .tint(Color.accent)
    }
}

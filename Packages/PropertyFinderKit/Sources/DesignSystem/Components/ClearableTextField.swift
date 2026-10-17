import Extensions
import SwiftUI

package struct ClearableTextField: View {
    let label: String
    let symbol: String?
    let accessibilityID: String
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    package init(
        label: String,
        symbol: String?,
        accessibilityID: String,
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding
    ) {
        self.label = label
        self.symbol = symbol
        self.accessibilityID = accessibilityID
        _text = text
        _isFocused = isFocused
    }

    package var body: some View {
        HStack(spacing: Spacing.pt8) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.body)
                    .foregroundStyle(Color.inputPlaceholder)
                    .accessibilityHidden(true)
            }
            TextField(label, text: $text, prompt: Text(label).foregroundStyle(Color.inputPlaceholder))
                .focused($isFocused)
                .onSubmit { isFocused = false }
                .accessibilityIdentifier(accessibilityID)
            if !text.isEmpty {
                Button {
                    text = ""
                    isFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.inputPlaceholder)
                        .expandingHitArea(by: Spacing.pt12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear text")
                .accessibilityIdentifier("\(accessibilityID).clear")
            }
        }
        .padding(.horizontal, Spacing.pt16)
        .frame(minHeight: 48)
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isFocused ? Color.accent : Color.inputBorder, lineWidth: 1)
                .allowsHitTesting(false)
        }
    }
}

import Extensions
import SwiftUI

package struct ClearableTextField: View {
    let label: String
    let symbol: String?
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    package init(label: String, symbol: String?, text: Binding<String>, isFocused: FocusState<Bool>.Binding) {
        self.label = label
        self.symbol = symbol
        _text = text
        _isFocused = isFocused
    }

    package var body: some View {
        HStack(spacing: Spacing.pt8) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.body)
                    .foregroundStyle(Color.inputPlaceholder)
            }
            TextField("", text: $text, prompt: Text(label).foregroundStyle(Color.inputPlaceholder))
                .focused($isFocused)
                .onSubmit { isFocused = false }
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

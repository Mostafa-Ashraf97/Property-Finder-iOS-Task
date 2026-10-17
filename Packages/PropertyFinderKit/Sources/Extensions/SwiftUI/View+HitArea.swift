import SwiftUI

package extension View {
    /// Expands compact controls to at least 44pt and compensates for the added padding.
    func expandingHitArea(by amount: CGFloat) -> some View {
        padding(amount)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .padding(-amount)
    }
}

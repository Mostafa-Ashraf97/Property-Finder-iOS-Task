import Foundation

package extension String {
    /// True when the string is empty or contains only whitespace and newlines.
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

import Foundation

package extension Error {
    /// True for cancellation from Swift concurrency or from URLSession, which should never be shown as a failure.
    var isCancellation: Bool {
        self is CancellationError || (self as? URLError)?.code == .cancelled
    }
}

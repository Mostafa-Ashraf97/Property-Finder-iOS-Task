import Foundation
import Network

public protocol NetworkMonitorProtocol: Sendable {
    /// The current network-path status, followed by changes. This does not guarantee that a server is reachable.
    func updates() -> AsyncStream<Bool>
}

public struct NetworkMonitor {
    public init() {}
}

extension NetworkMonitor: NetworkMonitorProtocol {
    public func updates() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { path in
                continuation.yield(path.status == .satisfied)
            }
            continuation.onTermination = { _ in
                monitor.cancel()
            }
            monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
        }
    }
}

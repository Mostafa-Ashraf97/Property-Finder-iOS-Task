import os

/// Logs a readable message plus optional private details.
///
/// `message` is always shown, so it must never contain personal data. `details` is shown only while debugging;
/// elsewhere, for example in Console or a sysdiagnose, it appears as `<private>`. Pass `nil` when there is nothing private.
public protocol LoggerProtocol: Sendable {
    func debug(_ message: String, private details: String?)
    func info(_ message: String, private details: String?)
    func error(_ message: String, private details: String?)
}

public struct AppLogger {
    private let logger = Logger()

    public init() {}

    private func log(_ level: OSLogType, _ message: String, details: String?) {
        if let details {
            logger.log(level: level, "\(message, privacy: .public): \(details, privacy: .private)")
        } else {
            logger.log(level: level, "\(message, privacy: .public)")
        }
    }
}

extension AppLogger: LoggerProtocol {
    public func debug(_ message: String, private details: String?) {
        log(.debug, message, details: details)
    }

    public func info(_ message: String, private details: String?) {
        log(.info, message, details: details)
    }

    public func error(_ message: String, private details: String?) {
        log(.error, message, details: details)
    }
}

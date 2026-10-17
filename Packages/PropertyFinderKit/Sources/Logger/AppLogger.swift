import Foundation
import os

public enum LogPrivacy: Sendable {
    /// Shown in full. Only for values that can never identify a person, such as counts or states.
    case `public`
    /// Redacted in collected logs by default; private values may be visible while debugging.
    case `private`
}

public protocol LoggerProtocol: Sendable {
    func debug(_ message: String, privacy: LogPrivacy)
    func info(_ message: String, privacy: LogPrivacy)
    func error(_ message: String, privacy: LogPrivacy)
}

public extension LoggerProtocol {
    func debug(_ message: String) {
        debug(message, privacy: .private)
    }

    func info(_ message: String) {
        info(message, privacy: .private)
    }

    func error(_ message: String) {
        error(message, privacy: .private)
    }
}

public struct AppLogger {
    private let logger = Logger()

    public init() {}
}

extension AppLogger: LoggerProtocol {
    public func debug(_ message: String, privacy: LogPrivacy) {
        switch privacy {
        case .public: logger.debug("\(message, privacy: .public)")
        case .private: logger.debug("\(message, privacy: .private)")
        }
    }

    public func info(_ message: String, privacy: LogPrivacy) {
        switch privacy {
        case .public: logger.info("\(message, privacy: .public)")
        case .private: logger.info("\(message, privacy: .private)")
        }
    }

    public func error(_ message: String, privacy: LogPrivacy) {
        switch privacy {
        case .public: logger.error("\(message, privacy: .public)")
        case .private: logger.error("\(message, privacy: .private)")
        }
    }
}

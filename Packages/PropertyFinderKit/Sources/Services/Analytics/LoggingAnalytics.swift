import Logger

public protocol AnalyticsTrackerProtocol: Sendable {
    func track(_ event: AnalyticsEvent)
}

public struct LoggingAnalytics {
    private let logger: any LoggerProtocol

    public init(logger: any LoggerProtocol) {
        self.logger = logger
    }
}

extension LoggingAnalytics: AnalyticsTrackerProtocol {
    public func track(_ event: AnalyticsEvent) {
        logger.debug("Analytics \(event.name)", private: event.parameters.isEmpty ? nil : String(describing: event.parameters))
    }
}

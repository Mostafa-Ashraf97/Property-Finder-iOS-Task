import Logger
import Synchronization
import Testing

struct LoggerProtocolTests {
    fileprivate final class RecordingLogger {
        private let privacies = Mutex<[LogPrivacy]>([])

        var recorded: [LogPrivacy] {
            privacies.withLock { $0 }
        }
    }

    @Test func redactsMessagesUnlessTheCallerOptsIn() {
        let logger = RecordingLogger()

        logger.debug("user typed an address")
        logger.info("user opened a listing")
        logger.error("request failed for a user")
        logger.error("Skipped 2 listings", privacy: .public)

        #expect(logger.recorded == [.private, .private, .private, .public])
    }
}

extension LoggerProtocolTests.RecordingLogger: LoggerProtocol {
    func debug(_: String, privacy: LogPrivacy) {
        privacies.withLock { $0.append(privacy) }
    }

    func info(_: String, privacy: LogPrivacy) {
        privacies.withLock { $0.append(privacy) }
    }

    func error(_: String, privacy: LogPrivacy) {
        privacies.withLock { $0.append(privacy) }
    }
}

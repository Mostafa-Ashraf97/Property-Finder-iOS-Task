public protocol FeatureFlagProviderProtocol: Sendable {
    func isEnabled(_ key: FeatureFlagKeys, defaultValue: Bool) -> Bool
}

public struct LocalFeatureFlagProvider {
    public init() {}
}

extension LocalFeatureFlagProvider: FeatureFlagProviderProtocol {
    public func isEnabled(_: FeatureFlagKeys, defaultValue _: Bool) -> Bool {
        // TODO: Look up key in the remote provider, using defaultValue as the fallback.
        true
    }
}

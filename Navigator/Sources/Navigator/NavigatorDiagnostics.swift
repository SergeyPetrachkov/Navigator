import Foundation

// MARK: - Navigator Diagnostics

/// Configuration for how the navigation system reports anomalies.
///
/// Production apps with hundreds of modules will eventually run into:
/// - Duplicate `RouteKey.id`s (two teams picked the same string).
/// - Navigation requests whose handler was never registered.
/// - Type mismatches between the `Parameter` at the call site and the handler.
///
/// Instead of silently breaking, the registry/router route these anomalies
/// through `NavigatorDiagnostics`. A composition root can swap the defaults
/// for a logger, Crashlytics hook, or unit-test spy.
///
/// ## Example
///
/// ```swift
/// let diagnostics = NavigatorDiagnostics(
///     duplicatePolicy: .assertInDebug,
///     logger: { logger.warning("[Navigator] \($0)") },
///     onUnresolvedRoute: { key in analytics.log(.navigatorUnresolvedRoute(key)) }
/// )
/// let registry = RouteRegistry(diagnostics: diagnostics)
/// ```
public struct NavigatorDiagnostics: Sendable {

    public enum TypeMismatchPolicy: Sendable {
        /// Report and trigger `assertionFailure` in debug builds.
        case assertInDebug
        /// Report without tripping a debug assertion.
        case reportOnly
    }

    /// What the registry should do when a second handler is registered for an id that
    /// already has one.
    public enum DuplicatePolicy: Sendable {
        /// Trip `assertionFailure` in debug, replace the existing handler in release.
        /// The safe default: loud in dev, lenient in production.
        case assertInDebug
        /// Always replace — useful for hot-swapping in tests or feature flags.
        case replaceSilently
        /// Keep the first registration, ignore the new one. The `logger` is still called.
        case refuse
    }

    public var duplicatePolicy: DuplicatePolicy
    public var typeMismatchPolicy: TypeMismatchPolicy
    public var logger: (@MainActor @Sendable (String) -> Void)?
    public var onUnresolvedRoute: (@MainActor @Sendable (_ key: String) -> Void)?
    public var onParameterTypeMismatch: (@MainActor @Sendable (_ key: String, _ expected: String, _ actual: String) -> Void)?

    public init(
        duplicatePolicy: DuplicatePolicy = .assertInDebug,
        typeMismatchPolicy: TypeMismatchPolicy = .assertInDebug,
        logger: (@MainActor @Sendable (String) -> Void)? = nil,
        onUnresolvedRoute: (@MainActor @Sendable (_ key: String) -> Void)? = nil,
        onParameterTypeMismatch: (@MainActor @Sendable (_ key: String, _ expected: String, _ actual: String) -> Void)? = nil
    ) {
        self.duplicatePolicy = duplicatePolicy
        self.typeMismatchPolicy = typeMismatchPolicy
        self.logger = logger
        self.onUnresolvedRoute = onUnresolvedRoute
        self.onParameterTypeMismatch = onParameterTypeMismatch
    }

    public static let `default` = NavigatorDiagnostics()
}

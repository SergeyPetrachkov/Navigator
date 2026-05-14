import Foundation

/// Reporting hooks and policies for navigation issues.
public struct NavigatorDiagnostics: Sendable {

    public enum TypeMismatchPolicy: Sendable {
        /// Report and trigger `assertionFailure` in debug builds.
        case assertInDebugReportInProd
        /// Report without tripping a debug assertion.
        case reportOnly
    }

    /// What the registry should do when a second handler is registered for an id that
    /// already has one.
    public enum DuplicatePolicy: Sendable {
        /// Trip `assertionFailure` in debug, replace the existing handler in release.
        case assertInDebugReportInProd
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
        duplicatePolicy: DuplicatePolicy = .assertInDebugReportInProd,
        typeMismatchPolicy: TypeMismatchPolicy = .assertInDebugReportInProd,
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


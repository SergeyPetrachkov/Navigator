import SwiftUI

// MARK: - Route Key

/// A type-safe identifier for a navigation destination.
///
/// `RouteKey` is open for extension — any module can contribute its own keys without
/// touching a central file. Keys are compared by `id` (a string) for hashing/equality
/// at the registry level, but they also carry a phantom `Parameter` type so the
/// compiler can enforce call-site and handler-side type safety.
///
/// ## Usage
///
/// ```swift
/// // In ChatInterface (an "Interface" module — no implementations, cheap to import)
/// public enum ChatRouteKey: RouteKey {
///     public typealias Parameter = Void
/// }
///
/// public enum ProfileRouteKey: RouteKey {
///     public typealias Parameter = UserID
/// }
/// ```
///
/// Any feature that wants to navigate to Profile imports `ProfileInterface`
/// (cheap, no view code). The feature that *implements* Profile imports
/// `ProfileInterface` *and* registers a `RouteHandler<ProfileRouteKey>`.
///
/// ## Identifier
///
/// Each key has a stable string `id` used at the registry layer. By default the `id`
/// is `String(reflecting: Self.self)` — the fully-qualified type name — which is
/// stable across builds and practically collision-free when module names are unique.
///
/// You can override `id` for human-readable deep links or URL paths:
///
/// ```swift
/// public enum ProfileRouteKey: RouteKey {
///     public typealias Parameter = UserID
///     public static let id = "profile"   // e.g. so deep links use /profile/:id
/// }
/// ```
///
/// If you override, remember that the registry uses the `id` for lookup. Duplicate
/// overrides across modules are detected by `RouteRegistry` (see `NavigatorDiagnostics`).
public protocol RouteKey {
    /// The data needed to navigate to this destination.
    associatedtype Parameter: Sendable

    /// Stable string identifier. Must be unique across the app.
    ///
    /// Default: the fully-qualified type name (`String(reflecting: Self.self)`).
    static var id: String { get }
}

public extension RouteKey {
    static var id: String { String(reflecting: Self.self) }
}

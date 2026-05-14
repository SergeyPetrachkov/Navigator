import Foundation

/// A type-erased navigation request that pairs a route key id with its parameter.
///
/// This is the "coin" that flows through the navigation system. Features never build these
/// by hand — they call `Navigator.navigate(to:parameter:)` or `.perform(_:)`.
public struct ResolvedRoute: Hashable, Identifiable, Sendable {

    /// A unique navigation event id so identical destinations can be pushed repeatedly.
    public let id: UUID

    /// The route key's stable string identifier used to resolve the destination.
    public let key: String

    /// The type-erased parameter. Cast back to the expected type inside the handler.
    public let parameter: AnySendable

    public init(
        id: UUID = UUID(),
        key: String,
        parameter: AnySendable
    ) {
        self.id = id
        self.key = key
        self.parameter = parameter
    }

    /// Builds a route from a typed key.
    public static func resolve<K: RouteKey>(_ key: K.Type, parameter: K.Parameter) -> ResolvedRoute {
        ResolvedRoute(key: key.id, parameter: AnySendable(parameter))
    }

    /// Builds a route from a Void-parameter key.
    public static func resolve<K: RouteKey>(_ key: K.Type) -> ResolvedRoute where K.Parameter == Void {
        ResolvedRoute(key: key.id, parameter: AnySendable(()))
    }

    // Equality and hashing are based on the navigation event id so the same destination
    // can be pushed repeatedly, and `NavigationStack` diffs each push correctly.
    public static func == (lhs: ResolvedRoute, rhs: ResolvedRoute) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - AnySendable

/// A type-erased container for a `Sendable` value, used to pass parameters across the
/// navigation boundary while keeping `ResolvedRoute` itself `Sendable`.
///
/// The underlying value is stored as `any Sendable`. Handlers cast back with `cast(to:)`
/// or access the raw `value` (typed as `Any`) when interoperating with SwiftUI.
public struct AnySendable: @unchecked Sendable {

    /// The erased storage. `any Sendable` keeps the Sendable guarantee at runtime, but
    /// because we can't express "opaque Sendable" in stored properties without
    /// `@unchecked`, the struct itself opts out of the checker.
    private let storage: any Sendable

    /// Internal accessor for `RouteRegistry` factory closures.
    internal var value: Any { storage }

    internal init(_ value: any Sendable) {
        self.storage = value
    }

    /// Casts the stored parameter to `T`.
    public func cast<T>(to _: T.Type = T.self) -> T? {
        storage as? T
    }
}

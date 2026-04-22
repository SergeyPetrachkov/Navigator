import Foundation

// MARK: - Resolved Route

/// A type-erased navigation request that pairs a route key id with its parameter.
///
/// This is the "coin" that flows through the navigation system. Features never build these
/// by hand — they call `Navigator.navigate(to:parameter:)` or `.perform(_:)`.
///
/// Why exists:
/// - `NavigationPath` and `.sheet(item:)` require a single concrete, `Hashable & Identifiable`
///   type. `ResolvedRoute` is that concrete type.
/// - Each pushed/presented route needs a unique identity so identical destinations can be
///   pushed repeatedly and `SwiftUI` can tell them apart.
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

    /// Convenience: build a `ResolvedRoute` from a statically-typed key.
    public static func resolve<K: RouteKey>(_ key: K.Type, parameter: K.Parameter) -> ResolvedRoute {
        ResolvedRoute(key: K.id, parameter: AnySendable(parameter))
    }

    /// Convenience: build a `ResolvedRoute` from a Void-parameter key.
    public static func resolve<K: RouteKey>(_ key: K.Type) -> ResolvedRoute where K.Parameter == Void {
        ResolvedRoute(key: K.id, parameter: AnySendable(()))
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

    /// Internal accessor for RouteRegistry factory closures
    internal var value: Any { storage }

    init(_ value: any Sendable) {
        self.storage = value
    }

    /// Typed cast helper. Returns `nil` if the erased type doesn't match `T`.
    func cast<T>(to type: T.Type = T.self) -> T? {
        storage as? T
    }
}

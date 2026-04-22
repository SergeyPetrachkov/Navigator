import SwiftUI

// MARK: - Route Registry

/// A mapping from route key ids to type-erased view factories.
///
/// The registry is the central "phone book" of the navigation system. At app startup
/// the composition root registers one factory per route key. At navigation time
/// `RoutingCoordinatorView` looks up the factory by id and calls it.
///
/// ## Two registration flavors
///
/// Use whichever fits your feature:
///
/// ### Handler-based (preferred for non-trivial handlers)
///
/// ```swift
/// struct ChatRouteHandler: RouteHandler {
///     typealias Key = ChatRouteKey
///     let dependencies: ChatDependenciesContainer
///
///     func destination(for parameter: Void) -> some View {
///         ChatCoordinatorView(dependencies: dependencies)
///     }
/// }
///
/// registry.register(ChatRouteHandler(dependencies: chatDeps))
/// ```
///
/// ### Block-based (preferred for trivial or one-liner handlers)
///
/// ```swift
/// registry.register(ProductDetailsRouteKey.self) { product in
///     ProductDetailsView(product: product)
/// }
/// ```
///
/// Both store the same kind of factory internally; the block form just saves
/// boilerplate when a handler doesn't need its own struct.
///
/// ## Diagnostics
///
/// A `NavigatorDiagnostics` value controls what happens on duplicate registration,
/// unresolved routes, and parameter type mismatches. See that type for details.
///
/// ## Thread safety
///
/// The registry is `@MainActor`-isolated. Registration happens at startup on main,
/// and lookups happen during SwiftUI body evaluation — also main.
@MainActor
@Observable
public final class RouteRegistry {

    /// Diagnostics used for duplicate handlers / unresolved routes / type mismatches.
    public var diagnostics: NavigatorDiagnostics

    // Type-erased factory: (Any) -> RouteResolution.
    // The `Any` is the route's Parameter, cast inside the closure.
    private var handlers: [String: @MainActor (Any) -> RouteResolution] = [:]

    public init(diagnostics: NavigatorDiagnostics = .default) {
        self.diagnostics = diagnostics
    }

    // MARK: - Registration

    /// Register a `RouteHandler` for its `Key`.
    public func register<H: RouteHandler>(_ handler: H) {
        let factory: @MainActor (Any) -> RouteResolution = { [diagnostics] parameter in
            guard let typed = parameter as? H.Key.Parameter else {
                return .failed(Self.reportTypeMismatch(
                    key: H.Key.id,
                    expected: H.Key.Parameter.self,
                    got: parameter,
                    diagnostics: diagnostics
                ))
            }
            return .resolved(AnyView(handler.destination(for: typed)))
        }
        install(H.Key.id, factory: factory)
    }

    /// Register a block-based handler for a `RouteKey`.
    ///
    /// Saves defining a dedicated `RouteHandler` struct when the destination is
    /// expressible as a single view-builder closure.
    public func register<K: RouteKey, V: View>(
        _ key: K.Type,
        @ViewBuilder destination: @escaping @MainActor (K.Parameter) -> V
    ) {
        let factory: @MainActor (Any) -> RouteResolution = { [diagnostics] parameter in
            guard let typed = parameter as? K.Parameter else {
                return .failed(Self.reportTypeMismatch(
                    key: K.id,
                    expected: K.Parameter.self,
                    got: parameter,
                    diagnostics: diagnostics
                ))
            }
            return .resolved(AnyView(destination(typed)))
        }
        install(K.id, factory: factory)
    }

    /// Register a block-based handler for a Void-parameter `RouteKey`.
    public func register<K: RouteKey, V: View>(
        _ key: K.Type,
        @ViewBuilder destination: @escaping @MainActor () -> V
    ) where K.Parameter == Void {
        register(key) { (_: Void) in destination() }
    }

    /// Register every route handler contributed by a feature module.
    public func register(_ module: any AppRouteModule) {
        module.registerRoutes(in: self)
    }

    /// Register route handlers from multiple modules in declaration order.
    public func register(_ modules: [any AppRouteModule]) {
        for module in modules {
            module.registerRoutes(in: self)
        }
    }

    // MARK: - Deregistration (tests / feature flags)

    /// Remove any handler registered for `K`. No-op if nothing is registered.
    public func unregister<K: RouteKey>(_ key: K.Type) {
        handlers.removeValue(forKey: K.id)
    }

    /// Remove every registered handler. Useful between tests.
    public func reset() {
        handlers.removeAll()
    }

    // MARK: - Resolution

    /// Resolve a `ResolvedRoute` into a typed result.
    public func resolve(_ route: ResolvedRoute) -> RouteResolution {
        guard let factory = handlers[route.key] else {
            diagnostics.logger?("[Navigator] No handler registered for route '\(route.key)'")
            diagnostics.onUnresolvedRoute?(route.key)
            return .failed(.unregisteredRoute(key: route.key))
        }
        return factory(route.parameter.value)
    }

    /// Returns `true` if a handler is registered for the given key.
    public func canHandle<K: RouteKey>(_ key: K.Type) -> Bool {
        handlers[K.id] != nil
    }

    /// Returns `true` if a handler is registered for the given id string.
    public func canHandle(id: String) -> Bool {
        handlers[id] != nil
    }

    /// Every route id currently registered. Useful for diagnostics dashboards / tests.
    public var registeredKeyIDs: [String] {
        Array(handlers.keys)
    }

    // MARK: - Internals

    private func install(_ id: String, factory: @MainActor @escaping (Any) -> RouteResolution) {
        if handlers[id] != nil {
            switch diagnostics.duplicatePolicy {
            case .assertInDebug:
                diagnostics.logger?("[Navigator] Duplicate handler for route '\(id)' — replacing.")
                assertionFailure(
                    "[Navigator] Duplicate handler for route '\(id)'. "
                    + "Either two RouteKeys share an id, or register(_:) was called twice. "
                    + "Override NavigatorDiagnostics.duplicatePolicy if you want this to be silent."
                )
            case .replaceSilently:
                break
            case .refuse:
                diagnostics.logger?("[Navigator] Duplicate handler for route '\(id)' — ignored.")
                return
            }
        }
        handlers[id] = factory
    }

    private static func reportTypeMismatch<Expected>(
        key: String,
        expected: Expected.Type,
        got value: Any,
        diagnostics: NavigatorDiagnostics
    ) -> RouteResolutionFailure {
        let expectedName = String(describing: Expected.self)
        let actualName = String(describing: type(of: value))
        diagnostics.logger?(
            "[Navigator] Type mismatch for route '\(key)': expected \(expectedName), got \(actualName)"
        )
        diagnostics.onParameterTypeMismatch?(key, expectedName, actualName)
        if diagnostics.typeMismatchPolicy == .assertInDebug {
            assertionFailure(
                "[Navigator] Type mismatch for route '\(key)': expected \(expectedName), got \(actualName)"
            )
        }
        return .parameterTypeMismatch(key: key, expected: expectedName, actual: actualName)
    }
}

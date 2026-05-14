import SwiftUI

/// A mapping from route key ids to type-erased view factories.
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
public final class RouteRegistry {

    /// Diagnostics used for duplicate handlers / unresolved routes / type mismatches.
    public let diagnostics: NavigatorDiagnostics

    internal let parentRegistry: RouteRegistry?

    // Type-erased factory: (Any) -> RouteResolution.
    // The `Any` is the route's Parameter, cast inside the closure.
    private var handlers: [String: @MainActor (Any) -> RouteResolution] = [:]

    public init(diagnostics: NavigatorDiagnostics = .default, parentRegistry: RouteRegistry? = nil) {
        self.diagnostics = diagnostics
        self.parentRegistry = parentRegistry
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

    /// Register a destination builder for a `RouteKey`.
    public func register<K: RouteKey, V: View>(
        _ key: K.Type,
        @ViewBuilder destination: @escaping @MainActor (K.Parameter) -> V
    ) {
        let factory: @MainActor (Any) -> RouteResolution = { [diagnostics] parameter in
            guard let typed = parameter as? K.Parameter else {
                return .failed(
                    Self.reportTypeMismatch(
                        key: key.id,
                        expected: K.Parameter.self,
                        got: parameter,
                        diagnostics: diagnostics
                    )
                )
            }
            return .resolved(AnyView(destination(typed)))
        }
        install(key.id, factory: factory)
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
        handlers.removeValue(forKey: key.id)
    }

    /// Remove every registered handler. Useful between tests.
    public func reset() {
        handlers.removeAll()
    }

    // MARK: - Resolution

    /// Resolves a route using local handlers first, then the parent registry.
    public func resolve(_ route: ResolvedRoute) -> RouteResolution {
        // first we look up in the current registry
        if let factory = handlers[route.key] {
            return factory(route.parameter.value)
        }
        // then we look up in the parent (which in turn can also look it up in its parent)
        if let parentRegistry {
            return parentRegistry.resolve(route)
        }
        // in the end we fall back to the unresolved route diagnostics
        diagnostics.logger?("[Navigator] No handler registered for route '\(route.key)'")
        diagnostics.onUnresolvedRoute?(route.key)
        return .failed(.unregisteredRoute(key: route.key))
    }

    /// Returns `true` if a handler is registered for the given key (checks in parent if present).
    public func canHandle<K: RouteKey>(_ key: K.Type) -> Bool {
        handlers[key.id] != nil || (parentRegistry?.canHandle(key) ?? false)
    }

    /// Returns `true` if a handler is registered for the given id string (checks in parent if present).
    public func canHandle(id: String) -> Bool {
        handlers[id] != nil || (parentRegistry?.canHandle(id: id) ?? false)
    }

    /// Every route id currently registered. Useful for diagnostics dashboards / tests.
    public var registeredKeyIDs: [String] {
        Array(handlers.keys)
    }

    /// Returns all route ids that cannot be resolved by the registry or its parents
    public func missingRouteIDs<S: Sequence>(outOf ids: S) -> [String] where S.Element == String {
        ids.filter { !canHandle(id: $0) }
    }

    // MARK: - Internals

    private func install(_ id: String, factory: @MainActor @escaping (Any) -> RouteResolution) {
        if handlers[id] != nil {
            switch diagnostics.duplicatePolicy {
            case .assertInDebugReportInProd:
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
        let expectedName = String(describing: expected)
        let actualName = String(describing: type(of: value))
        diagnostics.logger?(
            "[Navigator] Type mismatch for route '\(key)': expected \(expectedName), got \(actualName)"
        )
        diagnostics.onParameterTypeMismatch?(key, expectedName, actualName)
        if diagnostics.typeMismatchPolicy == .assertInDebugReportInProd {
            assertionFailure(
                "[Navigator] Type mismatch for route '\(key)': expected \(expectedName), got \(actualName)"
            )
        }
        return .parameterTypeMismatch(key: key, expected: expectedName, actual: actualName)
    }
}


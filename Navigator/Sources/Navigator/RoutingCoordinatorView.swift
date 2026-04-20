import SwiftUI

// MARK: - Routing Coordinator View

/// A drop-in SwiftUI view that wires `Navigator` and `RouteRegistry` into a `NavigationStack`.
///
/// `RoutingCoordinatorView` observes the router's `path` and `presentingSheet`, resolves
/// each `ResolvedRoute` through the registry, and injects both the router and the
/// registry into the environment so features can reach them with `@Environment(...)`.
///
/// ## Usage
///
/// ```swift
/// @State private var router = Navigator()
/// @State private var registry = RouteRegistry()
///
/// var body: some Scene {
///     WindowGroup {
///         RoutingCoordinatorView(router: router, registry: registry) {
///             DailyLogView(store: ...)
///         }
///     }
/// }
/// ```
///
/// Features never import this type. They only import `Navigator` and interact with `Navigator`.
///
/// ## Customizing the "missing route" fallback
///
/// A composition root can inject a custom view that's rendered when a route has no
/// registered handler. Use `.missingRouteView { route in … }`:
///
/// ```swift
/// RoutingCoordinatorView(router: router, registry: registry) { ... }
///     .missingRouteView { route in
///         CrashReporter.log("Unresolved route: \(route.key)")
///         return EmptyView()
///     }
/// ```
///
/// The default fallback is a debug-only diagnostic view and `EmptyView` in release.
public struct RoutingCoordinatorView<Root: View>: View {

    @Bindable private var router: Navigator
    private let registry: RouteRegistry
    private let root: Root

    @Environment(\.navigatorMissingRouteView) private var missingRouteView

    public init(
        router: Navigator,
        registry: RouteRegistry,
        @ViewBuilder root: () -> Root
    ) {
        self.router = router
        self.registry = registry
        self.root = root()
    }

    public var body: some View {
        NavigationStack(path: $router.path) {
            root
                .navigationDestination(for: ResolvedRoute.self) { route in
                    resolve(route)
                }
        }
        .sheet(item: $router.presentingSheet) { route in
            resolve(route)
        }
        .environment(router)
        .environment(registry)
    }

    @ViewBuilder
    private func resolve(_ route: ResolvedRoute) -> some View {
        if let view = registry.view(for: route) {
            view
        } else {
            missingRouteView(route)
        }
    }
}

// MARK: - Missing-route view environment

/// The closure invoked when a `ResolvedRoute` cannot be resolved by the registry.
///
/// Install a custom fallback via the `.missingRouteView { … }` view modifier. The
/// default fallback shows a debug diagnostic and returns an empty view in release.
public typealias MissingRouteView = @MainActor (ResolvedRoute) -> AnyView

private struct MissingRouteViewKey: EnvironmentKey {
    static let defaultValue: MissingRouteView = { route in
        #if DEBUG
        AnyView(
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                Text("No handler for route '\(route.key)'")
                    .font(.headline)
                Text("Register a RouteHandler or call registry.register(...) at composition time.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding()
        )
        #else
        AnyView(EmptyView())
        #endif
    }
}

extension EnvironmentValues {
    /// The fallback builder invoked when the registry cannot resolve a route.
    public var navigatorMissingRouteView: MissingRouteView {
        get { self[MissingRouteViewKey.self] }
        set { self[MissingRouteViewKey.self] = newValue }
    }
}

extension View {
    /// Install a custom fallback for unresolved routes in this subtree.
    public func missingRouteView(@ViewBuilder _ builder: @escaping @MainActor (ResolvedRoute) -> some View) -> some View {
        environment(\.navigatorMissingRouteView, { route in AnyView(builder(route)) })
    }
}

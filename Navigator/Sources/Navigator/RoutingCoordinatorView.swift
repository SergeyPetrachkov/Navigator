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
/// Features never import this type. They only import `Navigator` and interact with it either
/// through `@Environment(Navigator.self)` in views or explicit dependency injection into stores.
///
/// ## Customizing the "missing route" fallback
///
/// A composition root can inject a custom view that's rendered when route resolution
/// fails. Use `.missingRouteView { failure, route in … }`:
///
/// ```swift
/// RoutingCoordinatorView(router: router, registry: registry) { ... }
///     .missingRouteView { failure, route in
///         CrashReporter.log("Route failure: \(failure)")
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
        coordinatorBody
    }

    @ViewBuilder
    private func resolve(_ route: ResolvedRoute) -> some View {
        switch registry.resolve(route) {
        case .resolved(let view):
            view
        case .failed(let failure):
            missingRouteView(failure, route)
        }
    }

    @ViewBuilder
    private var coordinatorBody: some View {
        let base = NavigationStack(path: $router.path) {
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

        #if os(iOS)
        base
            .fullScreenCover(item: $router.presentingFullScreenCover) { route in
                resolve(route)
            }
        #else
        base
        #endif
    }
}

// MARK: - Missing-route view environment

/// The closure invoked when a `ResolvedRoute` cannot be resolved by the registry.
///
/// Install a custom fallback via the `.missingRouteView { … }` view modifier. The
/// default fallback shows a diagnostic in every build so production users do not end up
/// on a blank screen if routing composition is broken.
public typealias MissingRouteView = @MainActor (RouteResolutionFailure, ResolvedRoute) -> AnyView

private struct MissingRouteViewKey: EnvironmentKey {
    static let defaultValue: MissingRouteView = { failure, route in
        AnyView(
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                Text("This screen is unavailable")
                    .font(.headline)
                Text(message(for: failure, route: route))
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding()
        )
    }

    private static func message(for failure: RouteResolutionFailure, route: ResolvedRoute) -> String {
        switch failure {
        case .unregisteredRoute:
            return "The app could not open route '\(route.key)'."
        case .parameterTypeMismatch(_, let expected, let actual):
            return "The app could not open route '\(route.key)' because it expected \(expected) but received \(actual)."
        }
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
    public func missingRouteView(@ViewBuilder _ builder: @escaping @MainActor (RouteResolutionFailure, ResolvedRoute) -> some View) -> some View {
        environment(\.navigatorMissingRouteView, { failure, route in AnyView(builder(failure, route)) })
    }
}

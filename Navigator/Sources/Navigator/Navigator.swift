import SwiftUI

// MARK: - Navigation Style

/// How a route should be presented when navigating.
public enum AppNavigationStyle: Sendable {
    /// Push onto the current navigation stack.
    case push
    /// Present as a modal sheet.
    case sheet
    /// Present as a full-screen cover.
    case fullScreenCover
    /// Replace the current navigation stack with a new root destination.
    case overridingRoot
}

// MARK: - Navigator

/// The navigation hub a feature uses to trigger navigation without knowing how destinations
/// are built.
///
/// ## Why this isn't called "Navigator"
///
/// A single app usually has **many** navigators. Each screen flow can host its own — a
/// parent navigator for the root stack, child navigators for modal flows like Chat or
/// Favorites, sibling navigators for tabs. The name reflects that fact: you're creating
/// a local navigator for this flow, not reaching for a global singleton.
///
/// ## Parent / child navigators
///
/// A child coordinator owns its own `Navigator` and `RouteRegistry`. Routes pushed via the
/// child navigator only affect the child's stack; the parent's stack is untouched. This is
/// how you nest flows without leaking destinations across boundaries:
///
/// ```swift
/// struct ChatCoordinatorView: View {
///     @State private var navigator = Navigator()
///     @State private var registry: RouteRegistry
///
///     init(dependencies: ChatDependencies) {
///         let registry = RouteRegistry()
///         registry.register(ChatSubRouteHandler(dependencies: dependencies))
///         _registry = State(initialValue: registry)
///     }
///
///     var body: some View {
///         RoutingCoordinatorView(navigator: navigator, registry: registry) {
///             ChatRootView()
///         }
///     }
/// }
/// ```
///
/// ## Feature-side usage
///
/// ```swift
/// @Environment(Navigator.self) private var navigator
///
/// Button("Open Chat") { navigator.navigate(to: ChatRouteKey.self) }
/// Button("Profile")   { navigator.navigate(to: ProfileRouteKey.self, parameter: userID, style: .sheet) }
/// ```
///
/// Stores can also receive a `Navigator` explicitly through their environment/dependencies.
/// This project uses that pattern for action-driven navigation side effects.
///
/// ## Deep-link usage
///
/// ```swift
/// navigator.perform(intent)
/// ```
///
/// ## Observing navigation
///
/// Assign `onEvent` to hook analytics, logs, or tests:
///
/// ```swift
/// navigator.onEvent = { event in analytics.track(event) }
/// ```
@MainActor
@Observable
public final class Navigator {

    /// The navigation stack. Bound to `NavigationStack(path:)`.
    public var path: [ResolvedRoute] = []

    /// The currently presented sheet, if any. Bound to `.sheet(item:)`.
    public var presentingSheet: ResolvedRoute?

    /// The currently presented full-screen cover, if any. Bound to `.fullScreenCover(item:)`.
    public var presentingFullScreenCover: ResolvedRoute?

    /// Observer called after each successful navigation mutation. Analytics / tests.
    public var onEvent: (@MainActor (NavigationEvent) -> Void)?

    public init() {}

    // MARK: - Navigation API (Key-based)

    /// Navigate to a route that takes no parameter.
    public func navigate<K: RouteKey>(
        to key: K.Type,
        style: AppNavigationStyle = .push
    ) where K.Parameter == Void {
        navigate(to: key, parameter: (), style: style)
    }

    /// Navigate to a route with a parameter.
    public func navigate<K: RouteKey>(
        to key: K.Type,
        parameter: K.Parameter,
        style: AppNavigationStyle = .push
    ) {
        let route = ResolvedRoute.resolve(key, parameter: parameter)
        apply(route, style: style)
    }

    // MARK: - Navigation API (Intent-based)

    /// Execute a pre-built `NavigationIntent`.
    public func perform(_ intent: NavigationIntent, style: AppNavigationStyle = .push) {
        apply(intent.makeResolvedRoute(), style: style)
    }

    /// Replace the entire navigation path with `intents` (deep-link entry point).
    ///
    /// The first intent becomes the root of the stack; the rest are pushed in order.
    /// Emits `replacedPath`.
    public func setPath(_ intents: [NavigationIntent]) {
        let resolved = intents.map { $0.makeResolvedRoute() }
        path = resolved
        onEvent?(.replacedPath(resolved))
    }

    // MARK: - Stack Operations

    /// Pop the top route from the navigation stack.
    public func pop() {
        pop(count: 1)
    }

    /// Pop `count` routes from the top of the navigation stack. Safe when `count`
    /// exceeds the stack size — clamps to the current depth.
    public func pop(count: Int) {
        guard count > 0, !path.isEmpty else { return }
        let actual = min(count, path.count)
        path.removeLast(actual)
        onEvent?(.popped(count: actual))
    }

    /// Pop back to the most recent occurrence of `key` in the stack.
    /// Returns `true` if a matching entry was found and popped to.
    @discardableResult
    public func pop<K: RouteKey>(to key: K.Type) -> Bool {
        guard let index = path.lastIndex(where: { $0.key == K.id }) else { return false }
        let popCount = path.count - 1 - index
        guard popCount > 0 else { return true }
        path.removeLast(popCount)
        onEvent?(.popped(count: popCount))
        return true
    }

    /// Pop to the root, clearing the entire stack.
    public func popToRoot() {
        guard !path.isEmpty else { return }
        path.removeAll()
        onEvent?(.poppedToRoot)
    }

    /// Dismiss any currently presented modal destination.
    public func dismiss() {
        guard presentingSheet != nil || presentingFullScreenCover != nil else { return }
        presentingSheet = nil
        presentingFullScreenCover = nil
        onEvent?(.dismissed)
    }

    // MARK: - Internals

    private func apply(_ route: ResolvedRoute, style: AppNavigationStyle) {
        switch style {
        case .push:
            path.append(route)
            onEvent?(.pushed(route))
        case .sheet:
            presentingSheet = route
            presentingFullScreenCover = nil
            onEvent?(.presented(route, style: .sheet))
        case .fullScreenCover:
            presentingFullScreenCover = route
            presentingSheet = nil
            onEvent?(.presented(route, style: .fullScreenCover))
        case .overridingRoot:
            path = [route]
            onEvent?(.replacedRoot(route))
        }
    }
}

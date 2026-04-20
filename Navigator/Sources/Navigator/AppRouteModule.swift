import Foundation

// MARK: - App Route Module

/// A feature module's public navigation contract.
///
/// Every feature that contributes routes exposes **one** `AppRouteModule` in its
/// implementation target. The composition root imports implementation modules and
/// calls `registry.register(module)` — that's the only line of composition code per
/// feature.
///
/// ## Typical layout for a feature
///
/// ```
/// ChatInterface       (cheap: types + route keys, no views)
/// └── ChatRouteKey       <-- other features import this
///
/// Chat                (heavy: view code, stores, use-cases)
/// ├── ChatRouteModule    <-- composition root imports this
/// │   registers a ChatRouteHandler
/// └── ChatRouteHandler   <-- internal; builds the view
/// ```
///
/// ## Example
///
/// ```swift
/// public struct ChatRouteModule: AppRouteModule {
///     let dependencies: ChatDependenciesContainer
///
///     public init(dependencies: ChatDependenciesContainer) {
///         self.dependencies = dependencies
///     }
///
///     public func registerRoutes(in registry: RouteRegistry) {
///         registry.register(ChatRouteKey.self) { _ in
///             ChatCoordinatorView(dependencies: self.dependencies)
///         }
///     }
/// }
/// ```
@MainActor
public protocol AppRouteModule {
    func registerRoutes(in registry: RouteRegistry)
}

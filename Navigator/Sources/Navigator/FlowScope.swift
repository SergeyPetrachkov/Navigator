import SwiftUI

// MARK: - FlowScope

/// A helper that constructs a flow's long-lived objects **exactly once** per view identity.
///
/// ## The problem it solves
///
/// SwiftUI's `@State` is eager: `@State private var store = FooStore(...)` evaluates `FooStore(...)`
/// every time the view struct is initialised. SwiftUI keeps only the **first** value for a given
/// view identity and silently discards the extras. Those discarded instances are still fully
/// constructed, and then `deinit`. If your store logs `deinit`, you'll see several prints per
/// presentation — and for non-trivial stores you're doing needless work.
///
/// The same problem applies to `Navigator()` and `RouteRegistry()` created at the same place —
/// each subsequent view init constructs a fresh instance that's immediately thrown away.
///
/// `FlowScope` solves this by constructing the scoped objects **lazily** the first time the view's
/// body asks for them, and caching them in a stable `@State` box.
///
/// ## Usage
///
/// Define a class that holds everything the flow needs (navigator, registry, stores, child
/// coordinators, etc.) and inject it via `@FlowScope`:
///
/// ```swift
/// @MainActor
/// private final class FavoritesFlow {
///     let navigator = Navigator()
///     let registry: RouteRegistry
///     let store: FavoritesStore
///
///     init(dependencies: DependenciesContainer) {
///         let registry = RouteRegistry()
///         registry.register(FavoritesMealDetailsRouteHandler(dependenciesContainer: dependencies))
///         self.registry = registry
///         self.store = FavoritesStore(
///             environment: .init(
///                 favoritesRepository: dependencies.favoritesRepository,
///                 router: navigator,
///                 logger: dependencies.logger,
///                 eventBus: dependencies.eventBus,
///                 debounceMilliseconds: 300
///             )
///         )
///     }
/// }
///
/// struct CoordinatedFavoritesView: View {
///     let dependencies: DependenciesContainer
///     @FlowScope private var flow: FavoritesFlow
///
///     var body: some View {
///         RoutingCoordinatorView(navigator: flow.navigator, registry: flow.registry) {
///             FavoritesView(store: flow.store)
///         }
///         .flowScope($flow) { FavoritesFlow(dependencies: dependencies) }
///     }
/// }
/// ```
///
/// The flow object is constructed on first body evaluation and reused for every subsequent
/// body pass. Closing the sheet releases it (and fires exactly one `deinit`).
@MainActor
@propertyWrapper
public struct FlowScope<Value: AnyObject>: DynamicProperty {

    @State private var box = Box()

    public init() {}

    public var wrappedValue: Value {
        guard let value = box.value else {
            preconditionFailure(
                "FlowScope accessed before `.flowScope(_:factory:)` installed a value. "
                + "Attach `.flowScope($yourFlow) { FlowType(...) }` to the view body."
            )
        }
        return value
    }

    public var projectedValue: FlowScope<Value> { self }

    @MainActor
    fileprivate final class Box {
        var value: Value?
    }

    fileprivate func install(_ factory: () -> Value) {
        if box.value == nil {
            box.value = factory()
        }
    }
}

extension View {
    /// Install a flow-scoped value into a `@FlowScope` property, constructing it at most once.
    ///
    /// The `factory` closure runs only the first time the modifier is applied for a given view
    /// identity. Subsequent body evaluations reuse the existing value — no throwaway instances.
    @MainActor
    public func flowScope<Value: AnyObject>(
        _ scope: FlowScope<Value>,
        factory: () -> Value
    ) -> some View {
        scope.install(factory)
        return self
    }
}

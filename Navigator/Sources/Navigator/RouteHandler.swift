import SwiftUI

// MARK: - Route Handler

/// A factory that produces a SwiftUI `View` for a given `RouteKey`.
///
/// Each feature module implements one `RouteHandler` per navigable destination it owns.
/// Handlers are registered in the `RouteRegistry` at composition time.
///
/// ## Usage
///
/// ```swift
/// // In ChatImplementation module
/// struct ChatRouteHandler: RouteHandler {
///     typealias Key = ChatRouteKey
///
///     let dependencies: ChatDependenciesContainer
///
///     func destination(for parameter: Void) -> some View {
///         ChatCoordinatorView(dependencies: dependencies)
///     }
/// }
/// ```
///
/// The `parameter` argument is the strongly-typed `Key.Parameter` that was passed
/// at navigation time. The registry takes care of the type-erasure/casting.
///
/// ## When to use a handler struct vs a block
///
/// - Use a handler **struct** when it owns state, dependencies, or private helpers —
///   i.e., anything you'd prefer to unit-test independently of the view.
/// - Use the **block-based** `RouteRegistry.register(_:destination:)` when the
///   destination is a single-line view expression with no surrounding logic.
@MainActor
public protocol RouteHandler {
    associatedtype Key: RouteKey
    associatedtype Body: View

    @ViewBuilder
    func destination(for parameter: Key.Parameter) -> Body
}

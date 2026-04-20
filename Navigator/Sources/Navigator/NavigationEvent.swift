import Foundation

// MARK: - Navigation Event

/// A signal emitted by `Navigator` after a successful navigation mutation.
///
/// Use it for:
/// - **Analytics**: log a screen view when `pushed` or `presented` fires.
/// - **Tests**: observe without SwiftUI by assigning `Navigator.onEvent` and asserting.
/// - **Debugging**: pipe events into a logger to see the navigation timeline.
///
/// Events are emitted on the `@MainActor` because the router itself is main-actor.
public enum NavigationEvent: Sendable {

    /// A route was pushed onto the navigation stack.
    case pushed(ResolvedRoute)

    /// A route was presented as a modal sheet.
    case presented(ResolvedRoute)

    /// The navigation stack was replaced by a single new root.
    case replacedRoot(ResolvedRoute)

    /// The navigation stack was replaced by an explicit list (deep link).
    case replacedPath([ResolvedRoute])

    /// `n` routes were popped from the navigation stack.
    case popped(count: Int)

    /// The stack was popped all the way to its root.
    case poppedToRoot

    /// The currently-presented sheet was dismissed.
    case dismissed
}

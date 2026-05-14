import Foundation

public enum NavigationPresentationStyle: Sendable {
    case sheet
    case fullScreenCover
}

/// An event emitted after a successful navigation mutation.
public enum NavigationEvent: Sendable {

    /// A route was pushed onto the navigation stack.
    case pushed(ResolvedRoute)

    /// A route was presented modally.
    case presented(ResolvedRoute, style: NavigationPresentationStyle)

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

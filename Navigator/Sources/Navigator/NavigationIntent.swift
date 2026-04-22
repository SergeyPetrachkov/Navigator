import Foundation

// MARK: - Navigation Intent

/// A router-independent description of "where to go and with what".
///
/// `NavigationIntent` separates *producing* a navigation request from *executing* it.
/// That separation is what makes the system scale:
///
/// - **Deep links** decode `URL`s into intents before a router exists.
/// - **Tests** assert that a feature produced an intent without spinning up SwiftUI.
/// - **Orchestrators** can queue intents before a child coordinator is on screen.
///
/// ## Producing an intent
///
/// ```swift
/// let intent = NavigationIntent(ProfileRouteKey.self, parameter: userID)
/// ```
///
/// For Void-parameter keys:
///
/// ```swift
/// let intent = NavigationIntent(ChatRouteKey.self)
/// ```
///
/// ## Executing an intent
///
/// ```swift
/// router.perform(intent, style: .sheet)
/// ```
///
/// ## Deep-link recipe
///
/// Compose a tiny decoder per feature (lives in the interface module, close to the key):
///
/// ```swift
/// public enum ProfileDeepLink {
///     public static func intent(from url: URL) -> NavigationIntent? {
///         guard url.pathComponents.dropFirst().first == "profile",
///               let raw = url.pathComponents.dropFirst(2).first,
///               let id = UserID(raw) else { return nil }
///         return NavigationIntent(ProfileRouteKey.self, parameter: id)
///     }
/// }
/// ```
///
/// Then the composition root wires them together:
///
/// ```swift
/// let decoders: [(URL) -> NavigationIntent?] = [
///     ProfileDeepLink.intent(from:),
///     ChatDeepLink.intent(from:),
///     // …
/// ]
/// if let intent = decoders.lazy.compactMap({ $0(url) }).first {
///     router.perform(intent)
/// }
/// ```
public struct NavigationIntent: Sendable {

    /// The route key's stable string identifier.
    public let key: String

    /// The type-erased parameter.
    public let parameter: AnySendable

    /// Build an intent for a statically-typed key with a parameter.
    public init<K: RouteKey>(_ key: K.Type, parameter: K.Parameter) {
        self.key = K.id
        self.parameter = AnySendable(parameter)
    }

    /// Build an intent for a Void-parameter key.
    public init<K: RouteKey>(_ key: K.Type) where K.Parameter == Void {
        self.key = K.id
        self.parameter = AnySendable(())
    }

    /// Resolve the intent into a `ResolvedRoute` (adds a fresh event id).
    public func makeResolvedRoute() -> ResolvedRoute {
        ResolvedRoute(key: key, parameter: parameter)
    }
}

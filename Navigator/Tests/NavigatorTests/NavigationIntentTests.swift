import Testing
import SwiftUI
@testable import Navigator

@MainActor
struct NavigationIntentTests {

    @Test("makeResolvedRoute produces a route with the matching key and parameter")
    func intentBuildsResolvedRoute() {
        let intent = NavigationIntent(StringRouteKey.self, parameter: "hi")
        let resolved = intent.makeResolvedRoute()
        #expect(resolved.key == StringRouteKey.id)
        #expect(resolved.parameter.cast(to: String.self) == "hi")
    }

    @Test("Void intent produces a route whose parameter casts back to Void")
    func voidIntent() {
        let intent = NavigationIntent(VoidRouteKey.self)
        let resolved = intent.makeResolvedRoute()
        #expect(resolved.key == VoidRouteKey.id)
        #expect(resolved.parameter.cast(to: Void.self) != nil)
    }
}

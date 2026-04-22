import Testing
import SwiftUI
@testable import Navigator

@MainActor
struct ResolvedRouteTests {

    @Test("static resolve(_:parameter:) sets the correct key and preserves the parameter")
    func staticFactoryWithParameter() {
        let route = ResolvedRoute.resolve(StringRouteKey.self, parameter: "hello")
        #expect(route.key == StringRouteKey.id)
        #expect(route.parameter.cast(to: String.self) == "hello")
    }

    @Test("static resolve(_:) for a Void-parameter key sets the correct key")
    func staticFactoryVoid() {
        let route = ResolvedRoute.resolve(VoidRouteKey.self)
        #expect(route.key == VoidRouteKey.id)
        #expect(route.parameter.cast(to: Void.self) != nil)
    }

    @Test("two routes built from the same key are not equal because each carries a distinct UUID")
    func twoRoutesFromSameKeyAreDistinct() {
        let a = ResolvedRoute.resolve(VoidRouteKey.self)
        let b = ResolvedRoute.resolve(VoidRouteKey.self)
        #expect(a != b)
        #expect(a.key == b.key)
    }

    @Test("two routes sharing the same UUID are equal regardless of their parameter values")
    func routeEqualityIsBasedOnUUID() {
        let id = UUID()
        let a = ResolvedRoute(id: id, key: StringRouteKey.id, parameter: AnySendable("x"))
        let b = ResolvedRoute(id: id, key: StringRouteKey.id, parameter: AnySendable("y"))
        #expect(a == b)
    }
}

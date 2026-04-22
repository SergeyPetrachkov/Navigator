import Testing
import SwiftUI
@testable import Navigator

@MainActor
struct RouteDuplicatePolicyTests {

    @Test(".refuse keeps the first-registered handler and ignores the second")
    func refusePolicyKeepsOriginal() {
        let registry = RouteRegistry(diagnostics: NavigatorDiagnostics(duplicatePolicy: .refuse))
        var callCount = 0
        registry.register(StringRouteKey.self) { _ in callCount += 1; return Text("first") }
        registry.register(StringRouteKey.self) { _ in callCount += 1; return Text("second") }
        _ = registry.resolve(ResolvedRoute.resolve(StringRouteKey.self, parameter: "x"))
        #expect(callCount == 1)
    }

    @Test(".replaceSilently replaces the first handler with the second")
    func replaceSilentlyPolicyReplacesOriginal() {
        let registry = RouteRegistry(diagnostics: NavigatorDiagnostics(duplicatePolicy: .replaceSilently))
        var whichRan = ""
        registry.register(StringRouteKey.self) { _ in whichRan = "first"; return Text("first") }
        registry.register(StringRouteKey.self) { _ in whichRan = "second"; return Text("second") }
        _ = registry.resolve(ResolvedRoute.resolve(StringRouteKey.self, parameter: "x"))
        #expect(whichRan == "second")
    }
}

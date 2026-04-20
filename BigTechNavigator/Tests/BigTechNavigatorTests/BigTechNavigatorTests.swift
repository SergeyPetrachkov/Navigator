import Testing
@testable import BigTechNavigator
import SwiftUI

// MARK: - Test keys

private enum TestRouteKey: RouteKey {
    typealias Parameter = String
    static let id = "test.route"
}

private enum VoidTestKey: RouteKey {
    typealias Parameter = Void
    static let id = "test.void"
}

// MARK: - Test handlers / modules

@MainActor
private struct TestRouteHandler: RouteHandler {
    typealias Key = TestRouteKey
    func destination(for parameter: String) -> some View {
        Text(parameter)
    }
}

@MainActor
private struct TestRouteModule: AppRouteModule {
    func registerRoutes(in registry: RouteRegistry) {
        registry.register(TestRouteHandler())
        registry.register(VoidTestKey.self) {
            Text("void")
        }
    }
}

// MARK: - Cross-feature scenarios

@Test("Navigator.overridingRoot replaces the stack instead of appending")
@MainActor
func overridingRootReplacesStack() {
    let router = Navigator()

    router.navigate(to: TestRouteKey.self, parameter: "first")
    router.navigate(to: TestRouteKey.self, parameter: "second")
    #expect(router.path.count == 2)

    router.navigate(to: TestRouteKey.self, parameter: "root", style: .overridingRoot)

    #expect(router.path.count == 1)
}

@Test("ResolvedRoute keeps repeated pushes distinct via unique ids")
@MainActor
func repeatedPushesStayDistinct() {
    let router = Navigator()

    router.navigate(to: TestRouteKey.self, parameter: "a")
    router.navigate(to: TestRouteKey.self, parameter: "b")

    #expect(router.path.count == 2)
    #expect(router.path[0] != router.path[1])
    #expect(router.path[0].key == TestRouteKey.id)
    #expect(router.path[1].key == TestRouteKey.id)
}

@Test("RouteRegistry registers every module in a list")
@MainActor
func registryRegistersModules() {
    let registry = RouteRegistry()
    registry.register([TestRouteModule()])

    #expect(registry.canHandle(TestRouteKey.self))
    #expect(registry.canHandle(VoidTestKey.self))
}

@Test("Deep link path: setPath replaces the stack with a sequence of intents")
@MainActor
func deepLinkSetPath() {
    let router = Navigator()

    router.setPath([
        NavigationIntent(TestRouteKey.self, parameter: "deep-a"),
        NavigationIntent(TestRouteKey.self, parameter: "deep-b"),
        NavigationIntent(VoidTestKey.self),
    ])

    #expect(router.path.count == 3)
    #expect(router.path[0].parameter.cast(to: String.self) == "deep-a")
    #expect(router.path[1].parameter.cast(to: String.self) == "deep-b")
    #expect(router.path[2].key == VoidTestKey.id)
}

@Test("onEvent observes cross-feature navigation for analytics/tests")
@MainActor
func onEventObservesNavigation() {
    let router = Navigator()
    var pushCount = 0
    var dismissCount = 0
    router.onEvent = { event in
        switch event {
        case .pushed: pushCount += 1
        case .dismissed: dismissCount += 1
        default: break
        }
    }

    router.navigate(to: TestRouteKey.self, parameter: "a")
    router.navigate(to: TestRouteKey.self, parameter: "b", style: .present)
    router.dismiss()

    #expect(pushCount == 1)
    #expect(dismissCount == 1)
}

@Test("Unresolved routes are reported through diagnostics instead of crashing silently")
@MainActor
func unresolvedRouteReportsDiagnostics() {
    var unresolvedKey: String?
    let registry = RouteRegistry(
        diagnostics: NavigatorDiagnostics(
            duplicatePolicy: .replaceSilently,
            onUnresolvedRoute: { key in unresolvedKey = key }
        )
    )

    _ = registry.view(for: ResolvedRoute.resolve(TestRouteKey.self, parameter: "x"))

    #expect(unresolvedKey == TestRouteKey.id)
}

@Test("Duplicate registration with .refuse policy preserves the first handler")
@MainActor
func duplicateRegistrationRefusedPolicy() {
    let registry = RouteRegistry(diagnostics: NavigatorDiagnostics(duplicatePolicy: .refuse))

    var winner = ""
    registry.register(TestRouteKey.self) { _ in
        winner = "first"
        return Text("1")
    }
    registry.register(TestRouteKey.self) { _ in
        winner = "second"
        return Text("2")
    }

    _ = registry.view(for: ResolvedRoute.resolve(TestRouteKey.self, parameter: "x"))
    #expect(winner == "first")
}

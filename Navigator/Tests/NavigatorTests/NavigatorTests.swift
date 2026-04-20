import Testing
import SwiftUI
@testable import Navigator

// MARK: - Test keys

private enum VoidRouteKey: RouteKey {
    typealias Parameter = Void
    static let id = "test.void"
}

private enum StringRouteKey: RouteKey {
    typealias Parameter = String
    static let id = "test.string"
}

private enum IntRouteKey: RouteKey {
    typealias Parameter = Int
    static let id = "test.int"
}

private enum DefaultIDRouteKey: RouteKey {
    typealias Parameter = Void
}

private enum OtherDefaultIDRouteKey: RouteKey {
    typealias Parameter = Void
}

// MARK: - Navigator

@MainActor
struct NavigatorTests {

    @Test("navigate(to:) with push style appends a ResolvedRoute to the path")
    func pushAppendsRoute() {
        let router = Navigator()

        router.navigate(to: VoidRouteKey.self)
        #expect(router.path.count == 1)
        #expect(router.path[0].key == VoidRouteKey.id)
        #expect(router.presentingSheet == nil)
    }

    @Test("navigate(to:style:.present) sets the presented sheet and leaves path untouched")
    func presentSetsSheet() {
        let router = Navigator()

        router.navigate(to: VoidRouteKey.self, style: .present)

        #expect(router.path.isEmpty)
        #expect(router.presentingSheet?.key == VoidRouteKey.id)
    }

    @Test("navigate(to:style:.overridingRoot) replaces the existing stack with a single route")
    func overridingRootReplacesStack() {
        let router = Navigator()

        router.navigate(to: VoidRouteKey.self)
        router.navigate(to: VoidRouteKey.self)
        router.navigate(to: VoidRouteKey.self)
        #expect(router.path.count == 3)

        router.navigate(to: StringRouteKey.self, parameter: "root", style: .overridingRoot)

        #expect(router.path.count == 1)
        #expect(router.path[0].key == StringRouteKey.id)
    }

    @Test("pop() removes the last route; is a no-op on empty")
    func popRemovesLastAndIsSafeWhenEmpty() {
        let router = Navigator()
        router.pop() // no crash
        #expect(router.path.isEmpty)

        router.navigate(to: VoidRouteKey.self)
        router.navigate(to: VoidRouteKey.self)
        #expect(router.path.count == 2)

        router.pop()
        #expect(router.path.count == 1)
        router.pop()
        #expect(router.path.isEmpty)
    }

    @Test("pop(count:) clamps when asked to pop more than the stack depth")
    func popCountClampsSafely() {
        let router = Navigator()
        router.navigate(to: VoidRouteKey.self)
        router.navigate(to: VoidRouteKey.self)

        router.pop(count: 10)
        #expect(router.path.isEmpty)
    }

    @Test("pop(to:) pops back to the last matching key and returns true")
    func popToMatchingKey() {
        let router = Navigator()
        router.navigate(to: StringRouteKey.self, parameter: "a")
        router.navigate(to: IntRouteKey.self, parameter: 1)
        router.navigate(to: IntRouteKey.self, parameter: 2)
        router.navigate(to: VoidRouteKey.self)

        let didPop = router.pop(to: IntRouteKey.self)

        #expect(didPop)
        #expect(router.path.count == 3)
        #expect(router.path.last?.key == IntRouteKey.id)
    }

    @Test("pop(to:) returns false when the key is not on the stack")
    func popToUnknownKey() {
        let router = Navigator()
        router.navigate(to: StringRouteKey.self, parameter: "a")

        let didPop = router.pop(to: VoidRouteKey.self)

        #expect(!didPop)
        #expect(router.path.count == 1)
    }

    @Test("popToRoot clears the stack")
    func popToRootClears() {
        let router = Navigator()
        router.navigate(to: VoidRouteKey.self)
        router.navigate(to: VoidRouteKey.self)

        router.popToRoot()
        #expect(router.path.isEmpty)
    }

    @Test("dismiss clears the presented sheet")
    func dismissClearsSheet() {
        let router = Navigator()
        router.navigate(to: VoidRouteKey.self, style: .present)
        router.dismiss()
        #expect(router.presentingSheet == nil)
    }

    @Test("perform(intent) pushes a route built from a NavigationIntent")
    func performIntent() {
        let router = Navigator()
        let intent = NavigationIntent(StringRouteKey.self, parameter: "hello")

        router.perform(intent)

        #expect(router.path.count == 1)
        #expect(router.path[0].key == StringRouteKey.id)
        #expect(router.path[0].parameter.cast(to: String.self) == "hello")
    }

    @Test("setPath replaces the stack with the intent list")
    func setPathReplacesStack() {
        let router = Navigator()
        router.navigate(to: VoidRouteKey.self)

        router.setPath([
            NavigationIntent(StringRouteKey.self, parameter: "a"),
            NavigationIntent(IntRouteKey.self, parameter: 1),
        ])

        #expect(router.path.count == 2)
        #expect(router.path[0].key == StringRouteKey.id)
        #expect(router.path[1].key == IntRouteKey.id)
    }

    @Test("onEvent emits events for every mutation")
    func onEventEmitsForMutations() {
        let router = Navigator()
        var events: [NavigationEvent] = []
        router.onEvent = { events.append($0) }

        router.navigate(to: VoidRouteKey.self)
        router.navigate(to: VoidRouteKey.self, style: .present)
        router.dismiss()
        router.navigate(to: VoidRouteKey.self, style: .overridingRoot)
        router.popToRoot()
        router.setPath([NavigationIntent(VoidRouteKey.self)])

        // We can't compare enums with associated values holding UUIDs directly — so
        // match the case kinds positionally.
        #expect(events.count == 6)
        if case .pushed = events[0] {} else { Issue.record("expected .pushed") }
        if case .presented = events[1] {} else { Issue.record("expected .presented") }
        if case .dismissed = events[2] {} else { Issue.record("expected .dismissed") }
        if case .replacedRoot = events[3] {} else { Issue.record("expected .replacedRoot") }
        if case .poppedToRoot = events[4] {} else { Issue.record("expected .poppedToRoot") }
        if case .replacedPath = events[5] {} else { Issue.record("expected .replacedPath") }
    }
}

// MARK: - NavigationIntent

@MainActor
struct NavigationIntentTests {

    @Test("Intent carries key id and parameter; makeResolvedRoute produces matching route")
    func intentBuildsResolvedRoute() {
        let intent = NavigationIntent(StringRouteKey.self, parameter: "hi")
        let resolved = intent.makeResolvedRoute()
        #expect(resolved.key == StringRouteKey.id)
        #expect(resolved.parameter.cast(to: String.self) == "hi")
    }

    @Test("Void intent builds a route with the Void parameter")
    func voidIntent() {
        let intent = NavigationIntent(VoidRouteKey.self)
        let resolved = intent.makeResolvedRoute()
        #expect(resolved.key == VoidRouteKey.id)
        #expect(resolved.parameter.cast(to: Void.self) != nil)
    }

    @Test("Intents with the same key are equal")
    func equalityIsByKey() {
        let a = NavigationIntent(StringRouteKey.self, parameter: "a")
        let b = NavigationIntent(StringRouteKey.self, parameter: "b")
        #expect(a == b)
    }
}

// MARK: - RouteKey default id

@MainActor
struct RouteKeyDefaultIDTests {

    @Test("Default id is derived from the type name and is stable")
    func defaultIDIsTypeName() {
        #expect(DefaultIDRouteKey.id == String(reflecting: DefaultIDRouteKey.self))
        #expect(OtherDefaultIDRouteKey.id == String(reflecting: OtherDefaultIDRouteKey.self))
        #expect(DefaultIDRouteKey.id != OtherDefaultIDRouteKey.id)
    }

    @Test("Explicit id overrides the default")
    func explicitIDWins() {
        #expect(VoidRouteKey.id == "test.void")
    }
}

// MARK: - RouteRegistry

@MainActor
private struct StringHandler: RouteHandler {
    typealias Key = StringRouteKey
    func destination(for parameter: String) -> some View {
        Text(parameter)
    }
}

@MainActor
private struct VoidHandler: RouteHandler {
    typealias Key = VoidRouteKey
    func destination(for parameter: Void) -> some View {
        Text("void")
    }
}

@MainActor
private struct TestModule: AppRouteModule {
    func registerRoutes(in registry: RouteRegistry) {
        registry.register(StringHandler())
        registry.register(VoidHandler())
    }
}

@MainActor
struct RouteRegistryTests {

    @Test("Handler-based registration makes the key resolvable")
    func handlerBasedRegistration() {
        let registry = RouteRegistry()
        registry.register(StringHandler())

        #expect(registry.canHandle(StringRouteKey.self))
        #expect(registry.registeredKeyIDs.contains(StringRouteKey.id))
    }

    @Test("Block-based registration makes the key resolvable")
    func blockBasedRegistration() {
        let registry = RouteRegistry()
        registry.register(IntRouteKey.self) { value in
            Text("\(value)")
        }

        #expect(registry.canHandle(IntRouteKey.self))
    }

    @Test("Void block-based registration works without ignoring the parameter explicitly")
    func voidBlockBasedRegistration() {
        let registry = RouteRegistry()
        registry.register(VoidRouteKey.self) {
            Text("done")
        }

        #expect(registry.canHandle(VoidRouteKey.self))
    }

    @Test("Module-based registration installs every handler")
    func moduleRegistration() {
        let registry = RouteRegistry()
        registry.register(TestModule())

        #expect(registry.canHandle(StringRouteKey.self))
        #expect(registry.canHandle(VoidRouteKey.self))
    }

    @Test("canHandle(id:) returns true for registered ids and false for unknown ones")
    func canHandleByID() {
        let registry = RouteRegistry()
        registry.register(StringHandler())

        #expect(registry.canHandle(id: StringRouteKey.id))
        #expect(!registry.canHandle(id: "some.other.id"))
    }

    @Test("unregister removes the handler for a key")
    func unregisterRemovesHandler() {
        let registry = RouteRegistry()
        registry.register(StringHandler())
        #expect(registry.canHandle(StringRouteKey.self))

        registry.unregister(StringRouteKey.self)
        #expect(!registry.canHandle(StringRouteKey.self))
    }

    @Test("reset clears every handler")
    func resetClearsRegistry() {
        let registry = RouteRegistry()
        registry.register(TestModule())
        registry.reset()
        #expect(registry.registeredKeyIDs.isEmpty)
    }

    @Test("view(for:) returns nil and reports an unresolved route when the key is unknown")
    func unresolvedRouteReportsDiagnostics() {
        var unresolvedKey: String?
        let registry = RouteRegistry(
            diagnostics: NavigatorDiagnostics(
                duplicatePolicy: .replaceSilently,
                onUnresolvedRoute: { key in unresolvedKey = key }
            )
        )

        let view = registry.view(for: ResolvedRoute.resolve(StringRouteKey.self, parameter: "x"))

        #expect(view == nil)
        #expect(unresolvedKey == StringRouteKey.id)
    }

    @Test("Duplicate registration under .refuse keeps the original handler")
    func duplicateRefuseKeepsOriginal() {
        let registry = RouteRegistry(diagnostics: NavigatorDiagnostics(duplicatePolicy: .refuse))
        var callCount = 0
        registry.register(StringRouteKey.self) { _ in
            callCount += 1
            return Text("first")
        }
        registry.register(StringRouteKey.self) { _ in
            callCount += 1
            return Text("second")
        }

        _ = registry.view(for: ResolvedRoute.resolve(StringRouteKey.self, parameter: "x"))
        #expect(callCount == 1) // first handler won
    }

    @Test("Duplicate registration under .replaceSilently replaces the original")
    func duplicateReplaceSilently() {
        let registry = RouteRegistry(diagnostics: NavigatorDiagnostics(duplicatePolicy: .replaceSilently))
        var whichRan = ""
        registry.register(StringRouteKey.self) { _ in
            whichRan = "first"
            return Text("first")
        }
        registry.register(StringRouteKey.self) { _ in
            whichRan = "second"
            return Text("second")
        }

        _ = registry.view(for: ResolvedRoute.resolve(StringRouteKey.self, parameter: "x"))
        #expect(whichRan == "second")
    }
}

// MARK: - AnySendable

@MainActor
struct AnySendableTests {

    @Test("cast returns the value when the type matches and nil otherwise")
    func castRoundTrips() {
        let erased = AnySendable("hello")
        #expect(erased.cast(to: String.self) == "hello")
        #expect(erased.cast(to: Int.self) == nil)
    }

    @Test("value accessor returns the stored value as Any for SwiftUI interop")
    func anyAccessor() {
        let erased = AnySendable(42)
        #expect(erased.value as? Int == 42)
    }
}

// MARK: - FlowScope

@MainActor
private final class ScopedFlow {
    static nonisolated(unsafe) var constructionCount = 0
    let id = UUID()

    init() { Self.constructionCount += 1 }
}

@MainActor
struct FlowScopeTests {

    @Test("Factory runs exactly once even if install is called many times")
    func factoryRunsOnce() {
        ScopedFlow.constructionCount = 0
        let scope = FlowScope<ScopedFlow>()

        // Simulate many body re-evaluations that each re-apply the modifier.
        let view = Color.clear
            .flowScope(scope) { ScopedFlow() }
            .flowScope(scope) { ScopedFlow() }
            .flowScope(scope) { ScopedFlow() }
        _ = view

        let first = scope.wrappedValue.id
        let second = scope.wrappedValue.id
        #expect(first == second)
        #expect(ScopedFlow.constructionCount == 1)
    }
}

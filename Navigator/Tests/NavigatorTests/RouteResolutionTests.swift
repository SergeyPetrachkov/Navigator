import Testing
import SwiftUI
@testable import Navigator

@MainActor
struct RouteResolutionTests {

    @Test("resolve returns .resolved for a route whose handler is registered")
    func resolveSucceeds() {
        let registry = RouteRegistry(diagnostics: NavigatorDiagnostics(duplicatePolicy: .replaceSilently))
        registry.register(StringHandler())
        let resolution = registry.resolve(ResolvedRoute.resolve(StringRouteKey.self, parameter: "ok"))
        if case .resolved = resolution {} else { Issue.record("expected .resolved") }
    }

    @Test("canHandle(id:) returns true for registered ids and false for unknown ones")
    func canHandleByStringID() {
        let registry = RouteRegistry()
        registry.register(StringHandler())
        #expect(registry.canHandle(id: StringRouteKey.id))
        #expect(!registry.canHandle(id: "no.such.route"))
    }

    @Test("resolve returns .unregisteredRoute and fires the diagnostics callback for an unknown key")
    func resolveUnknownKeyReportsFailure() {
        var unresolvedKey: String?
        let registry = RouteRegistry(
            diagnostics: NavigatorDiagnostics(
                duplicatePolicy: .replaceSilently,
                onUnresolvedRoute: { unresolvedKey = $0 }
            )
        )

        let resolution = registry.resolve(ResolvedRoute.resolve(StringRouteKey.self, parameter: "x"))

        if case .failed(.unregisteredRoute(let key)) = resolution {
            #expect(key == StringRouteKey.id)
        } else {
            Issue.record("expected .failed(.unregisteredRoute)")
        }
        #expect(unresolvedKey == StringRouteKey.id)
    }

    @Test("resolve returns .parameterTypeMismatch and fires the diagnostics callback on a type mismatch")
    func resolveTypeMismatchReportsFailure() {
        var mismatch: (String, String, String)?
        let registry = RouteRegistry(
            diagnostics: NavigatorDiagnostics(
                duplicatePolicy: .replaceSilently,
                typeMismatchPolicy: .reportOnly,
                onParameterTypeMismatch: { mismatch = ($0, $1, $2) }
            )
        )
        registry.register(StringHandler())

        let resolution = registry.resolve(ResolvedRoute(key: StringRouteKey.id, parameter: AnySendable(1)))

        if case .failed(.parameterTypeMismatch(let key, let expected, let actual)) = resolution {
            #expect(key == StringRouteKey.id)
            #expect(expected == String(describing: String.self))
            #expect(actual == String(describing: Int.self))
        } else {
            Issue.record("expected .failed(.parameterTypeMismatch)")
        }
        #expect(mismatch?.0 == StringRouteKey.id)
        #expect(mismatch?.1 == String(describing: String.self))
        #expect(mismatch?.2 == String(describing: Int.self))
    }

    @Test("child registry resolves and reports canHandle for a route registered only in the parent")
    func parentRegistryFallback() {
        let parent = RouteRegistry(diagnostics: NavigatorDiagnostics(duplicatePolicy: .replaceSilently))
        parent.register(StringHandler())

        let child = RouteRegistry(
            diagnostics: NavigatorDiagnostics(duplicatePolicy: .replaceSilently),
            parentRegistry: parent
        )

        #expect(child.canHandle(StringRouteKey.self))
        let resolution = child.resolve(ResolvedRoute.resolve(StringRouteKey.self, parameter: "from parent"))
        if case .resolved = resolution {} else { Issue.record("expected .resolved via parent") }
    }

    @Test("child handler is called instead of the parent's handler when both register the same key")
    func childHandlerTakesPrecedenceOverParent() {
        let parent = RouteRegistry(diagnostics: NavigatorDiagnostics(duplicatePolicy: .replaceSilently))
        var parentCalled = false
        parent.register(StringRouteKey.self) { _ in parentCalled = true; return Text("parent") }

        let child = RouteRegistry(
            diagnostics: NavigatorDiagnostics(duplicatePolicy: .replaceSilently),
            parentRegistry: parent
        )
        var childCalled = false
        child.register(StringRouteKey.self) { _ in childCalled = true; return Text("child") }

        _ = child.resolve(ResolvedRoute.resolve(StringRouteKey.self, parameter: "x"))
        #expect(childCalled)
        #expect(!parentCalled)
    }

    @Test("resolve returns .unregisteredRoute when the key is absent from both child and parent")
    func missingFromBothChildAndParentFails() {
        let parent = RouteRegistry(diagnostics: NavigatorDiagnostics(duplicatePolicy: .replaceSilently))
        let child = RouteRegistry(
            diagnostics: NavigatorDiagnostics(
                duplicatePolicy: .replaceSilently,
                onUnresolvedRoute: { _ in }
            ),
            parentRegistry: parent
        )

        let resolution = child.resolve(ResolvedRoute.resolve(StringRouteKey.self, parameter: "x"))
        if case .failed(.unregisteredRoute(let key)) = resolution {
            #expect(key == StringRouteKey.id)
        } else {
            Issue.record("expected .failed(.unregisteredRoute)")
        }
    }
}

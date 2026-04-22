import Testing
import SwiftUI
@testable import Navigator

@MainActor
struct RouteRegistrationTests {

    @Test("handler-based registration makes the key resolvable and appears in registeredKeyIDs")
    func handlerBasedRegistration() {
        let registry = RouteRegistry()
        registry.register(StringHandler())
        #expect(registry.canHandle(StringRouteKey.self))
        #expect(registry.registeredKeyIDs.contains(StringRouteKey.id))
    }

    @Test("block-based registration with a parameter makes the key resolvable")
    func blockBasedRegistration() {
        let registry = RouteRegistry()
        registry.register(IntRouteKey.self) { value in Text("\(value)") }
        #expect(registry.canHandle(IntRouteKey.self))
    }

    @Test("block-based registration for a Void-parameter key works without capturing the parameter")
    func voidBlockBasedRegistration() {
        let registry = RouteRegistry()
        registry.register(VoidRouteKey.self) { Text("done") }
        #expect(registry.canHandle(VoidRouteKey.self))
    }

    @Test("module-based registration installs every handler declared by the module")
    func moduleRegistration() {
        let registry = RouteRegistry()
        registry.register(StringAndVoidModule())
        #expect(registry.canHandle(StringRouteKey.self))
        #expect(registry.canHandle(VoidRouteKey.self))
    }

    @Test("registering multiple modules installs all of their handlers")
    func bulkModuleRegistration() {
        let registry = RouteRegistry(diagnostics: NavigatorDiagnostics(duplicatePolicy: .replaceSilently))
        registry.register([StringAndVoidModule(), IntModule()])
        #expect(registry.canHandle(StringRouteKey.self))
        #expect(registry.canHandle(VoidRouteKey.self))
        #expect(registry.canHandle(IntRouteKey.self))
    }

    @Test("registeredKeyIDs contains every registered key")
    func registeredKeyIDsContainsAll() {
        let registry = RouteRegistry(diagnostics: NavigatorDiagnostics(duplicatePolicy: .replaceSilently))
        registry.register([StringAndVoidModule(), IntModule()])
        let ids = Set(registry.registeredKeyIDs)
        #expect(ids.contains(StringRouteKey.id))
        #expect(ids.contains(VoidRouteKey.id))
        #expect(ids.contains(IntRouteKey.id))
    }

    @Test("unregister removes the handler so the key is no longer resolvable")
    func unregisterRemovesHandler() {
        let registry = RouteRegistry()
        registry.register(StringHandler())
        registry.unregister(StringRouteKey.self)
        #expect(!registry.canHandle(StringRouteKey.self))
        #expect(!registry.canHandle(id: StringRouteKey.id))
    }

    @Test("reset removes every handler and empties registeredKeyIDs")
    func resetClearsRegistry() {
        let registry = RouteRegistry(diagnostics: NavigatorDiagnostics(duplicatePolicy: .replaceSilently))
        registry.register([StringAndVoidModule(), IntModule()])
        registry.reset()
        #expect(registry.registeredKeyIDs.isEmpty)
        #expect(!registry.canHandle(StringRouteKey.self))
        #expect(!registry.canHandle(VoidRouteKey.self))
    }
}

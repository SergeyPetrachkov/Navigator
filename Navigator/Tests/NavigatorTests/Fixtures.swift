import Testing
import SwiftUI
@testable import Navigator

enum VoidRouteKey: RouteKey {
    typealias Parameter = Void
    static let id = "test.void"
}

enum StringRouteKey: RouteKey {
    typealias Parameter = String
    static let id = "test.string"
}

enum IntRouteKey: RouteKey {
    typealias Parameter = Int
    static let id = "test.int"
}

enum DefaultIDRouteKey: RouteKey {
    typealias Parameter = Void
}

enum OtherDefaultIDRouteKey: RouteKey {
    typealias Parameter = Void
}

@MainActor
struct StringHandler: RouteHandler {
    typealias Key = StringRouteKey
    func destination(for parameter: String) -> some View { Text(parameter) }
}

@MainActor
struct VoidHandler: RouteHandler {
    typealias Key = VoidRouteKey
    func destination(for parameter: Void) -> some View { Text("void") }
}

@MainActor
struct StringAndVoidModule: AppRouteModule {
    func registerRoutes(in registry: RouteRegistry) {
        registry.register(StringHandler())
        registry.register(VoidHandler())
    }
}

@MainActor
struct IntModule: AppRouteModule {
    func registerRoutes(in registry: RouteRegistry) {
        registry.register(IntRouteKey.self) { value in Text("\(value)") }
    }
}

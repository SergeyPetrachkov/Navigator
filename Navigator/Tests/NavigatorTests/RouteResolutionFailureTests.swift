import Testing
import SwiftUI
@testable import Navigator

@MainActor
struct RouteResolutionFailureTests {

    @Test("routeKey returns the key from an .unregisteredRoute failure")
    func routeKeyForUnregisteredRoute() {
        let failure = RouteResolutionFailure.unregisteredRoute(key: "my.route")
        #expect(failure.routeKey == "my.route")
    }

    @Test("routeKey returns the key from a .parameterTypeMismatch failure")
    func routeKeyForTypeMismatch() {
        let failure = RouteResolutionFailure.parameterTypeMismatch(key: "my.route", expected: "String", actual: "Int")
        #expect(failure.routeKey == "my.route")
    }

    @Test(".unregisteredRoute values are equal when they carry the same key")
    func unregisteredRouteEquality() {
        #expect(RouteResolutionFailure.unregisteredRoute(key: "k") == .unregisteredRoute(key: "k"))
        #expect(RouteResolutionFailure.unregisteredRoute(key: "k") != .unregisteredRoute(key: "other"))
    }

    @Test(".parameterTypeMismatch values are equal when all three fields match")
    func typeMismatchEquality() {
        let a = RouteResolutionFailure.parameterTypeMismatch(key: "k", expected: "String", actual: "Int")
        let b = RouteResolutionFailure.parameterTypeMismatch(key: "k", expected: "String", actual: "Int")
        let c = RouteResolutionFailure.parameterTypeMismatch(key: "k", expected: "String", actual: "Double")
        #expect(a == b)
        #expect(a != c)
    }
}

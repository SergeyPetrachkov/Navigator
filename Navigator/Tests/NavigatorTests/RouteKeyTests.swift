import Testing
import SwiftUI
@testable import Navigator

@MainActor
struct RouteKeyTests {

    @Test("default id is the fully-qualified type name and is unique per type")
    func defaultIDIsFullyQualifiedTypeName() {
        #expect(DefaultIDRouteKey.id == String(reflecting: DefaultIDRouteKey.self))
        #expect(OtherDefaultIDRouteKey.id == String(reflecting: OtherDefaultIDRouteKey.self))
        #expect(DefaultIDRouteKey.id != OtherDefaultIDRouteKey.id)
    }

    @Test("explicit id override wins over the default")
    func explicitIDWins() {
        #expect(VoidRouteKey.id == "test.void")
    }
}

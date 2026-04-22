import Testing
import SwiftUI
@testable import Navigator

@MainActor
struct AnySendableTests {

    @Test("cast returns the value when the type matches and nil when it doesn't")
    func castRoundTrips() {
        let erased = AnySendable("hello")
        #expect(erased.cast(to: String.self) == "hello")
        #expect(erased.cast(to: Int.self) == nil)
    }

    @Test("value accessor exposes the erased value as Any for SwiftUI interop")
    func anyAccessor() {
        let erased = AnySendable(42)
        #expect(erased.value as? Int == 42)
    }
}

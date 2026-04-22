import Testing
import SwiftUI
@testable import Navigator

@MainActor
struct StackOperationTests {

    @Test("pop() removes the top route and is a no-op on an empty stack")
    func popRemovesTopAndIsSafeWhenEmpty() {
        let router = Navigator()
        router.pop()
        #expect(router.path.isEmpty)

        router.navigate(to: VoidRouteKey.self)
        router.navigate(to: VoidRouteKey.self)
        router.pop()
        #expect(router.path.count == 1)
        router.pop()
        #expect(router.path.isEmpty)
    }

    @Test("pop(count: 0) is a no-op")
    func popCountZeroIsNoOp() {
        let router = Navigator()
        router.navigate(to: VoidRouteKey.self)
        router.pop(count: 0)
        #expect(router.path.count == 1)
    }

    @Test("pop(count:) equal to the stack depth clears the stack")
    func popCountExactDepthClearsStack() {
        let router = Navigator()
        router.navigate(to: VoidRouteKey.self)
        router.navigate(to: VoidRouteKey.self)
        router.pop(count: 2)
        #expect(router.path.isEmpty)
    }

    @Test("pop(count:) clamps to the stack depth when the requested count exceeds it")
    func popCountClampsSafely() {
        let router = Navigator()
        router.navigate(to: VoidRouteKey.self)
        router.navigate(to: VoidRouteKey.self)
        router.pop(count: 10)
        #expect(router.path.isEmpty)
    }

    @Test("pop(to:) pops back to the most recent matching key and returns true")
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

    @Test("pop(to:) when the key appears multiple times pops to the most recent occurrence")
    func popToMultipleOccurrencesPopsToLast() {
        let router = Navigator()
        router.navigate(to: IntRouteKey.self, parameter: 1)
        router.navigate(to: IntRouteKey.self, parameter: 2)
        router.navigate(to: VoidRouteKey.self)
        router.navigate(to: VoidRouteKey.self)

        // Stack: [Int(1), Int(2), Void, Void]; lastIndex of IntRouteKey = 1 → pops 2 above it
        let didPop = router.pop(to: IntRouteKey.self)

        #expect(didPop)
        #expect(router.path.count == 2)
        #expect(router.path.last?.key == IntRouteKey.id)
        #expect(router.path.last?.parameter.cast(to: Int.self) == 2)
    }

    @Test("pop(to:) when the key is already the top item returns true without changing the stack")
    func popToKeyAlreadyAtTopIsNoOp() {
        let router = Navigator()
        router.navigate(to: StringRouteKey.self, parameter: "a")
        router.navigate(to: VoidRouteKey.self)
        let didPop = router.pop(to: VoidRouteKey.self)
        #expect(didPop)
        #expect(router.path.count == 2)
    }

    @Test("pop(to:) returns false and leaves the stack unchanged when the key is absent")
    func popToAbsentKeyReturnsFalse() {
        let router = Navigator()
        router.navigate(to: StringRouteKey.self, parameter: "a")
        let didPop = router.pop(to: VoidRouteKey.self)
        #expect(!didPop)
        #expect(router.path.count == 1)
    }

    @Test("popToRoot clears the entire stack")
    func popToRootClears() {
        let router = Navigator()
        router.navigate(to: VoidRouteKey.self)
        router.navigate(to: VoidRouteKey.self)
        router.popToRoot()
        #expect(router.path.isEmpty)
    }

    @Test("dismiss clears a presented sheet")
    func dismissClearsSheet() {
        let router = Navigator()
        router.navigate(to: VoidRouteKey.self, style: .sheet)
        router.dismiss()
        #expect(router.presentingSheet == nil)
    }

    @Test("dismiss clears a presented full-screen cover")
    func dismissClearsFullScreenCover() {
        let router = Navigator()
        router.navigate(to: VoidRouteKey.self, style: .fullScreenCover)
        router.dismiss()
        #expect(router.presentingFullScreenCover == nil)
    }

    @Test("dismiss is a no-op when nothing is presented")
    func dismissWhenNothingPresentedIsNoOp() {
        let router = Navigator()
        router.dismiss()
        #expect(router.presentingSheet == nil)
        #expect(router.presentingFullScreenCover == nil)
    }

    @Test("setPath replaces the current stack with the resolved intents in order")
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

    @Test("setPath([]) clears the stack")
    func setPathWithEmptyArrayClearsStack() {
        let router = Navigator()
        router.navigate(to: VoidRouteKey.self)
        router.setPath([])
        #expect(router.path.isEmpty)
    }
}

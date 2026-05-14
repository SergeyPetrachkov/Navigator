import Testing
import SwiftUI
@testable import Navigator

@MainActor
struct StackOperationTests {

    @Test("pop() removes the top route and is a no-op on an empty stack")
    func popRemovesTopAndIsSafeWhenEmpty() {
        let navigator = Navigator()
        navigator.pop()
        #expect(navigator.path.isEmpty)

        navigator.navigate(to: VoidRouteKey.self)
        navigator.navigate(to: VoidRouteKey.self)
        navigator.pop()
        #expect(navigator.path.count == 1)
        navigator.pop()
        #expect(navigator.path.isEmpty)
    }

    @Test("pop(count: 0) is a no-op")
    func popCountZeroIsNoOp() {
        let navigator = Navigator()
        navigator.navigate(to: VoidRouteKey.self)
        navigator.pop(count: 0)
        #expect(navigator.path.count == 1)
    }

    @Test("pop(count:) equal to the stack depth clears the stack")
    func popCountExactDepthClearsStack() {
        let navigator = Navigator()
        navigator.navigate(to: VoidRouteKey.self)
        navigator.navigate(to: VoidRouteKey.self)
        navigator.pop(count: 2)
        #expect(navigator.path.isEmpty)
    }

    @Test("pop(count:) clamps to the stack depth when the requested count exceeds it")
    func popCountClampsSafely() {
        let navigator = Navigator()
        navigator.navigate(to: VoidRouteKey.self)
        navigator.navigate(to: VoidRouteKey.self)
        navigator.pop(count: 10)
        #expect(navigator.path.isEmpty)
    }

    @Test("pop(to:) pops back to the most recent matching key and returns true")
    func popToMatchingKey() {
        let navigator = Navigator()
        navigator.navigate(to: StringRouteKey.self, parameter: "a")
        navigator.navigate(to: IntRouteKey.self, parameter: 1)
        navigator.navigate(to: IntRouteKey.self, parameter: 2)
        navigator.navigate(to: VoidRouteKey.self)

        let didPop = navigator.pop(to: IntRouteKey.self)

        #expect(didPop)
        #expect(navigator.path.count == 3)
        #expect(navigator.path.last?.key == IntRouteKey.id)
    }

    @Test("pop(to:) when the key appears multiple times pops to the most recent occurrence")
    func popToMultipleOccurrencesPopsToLast() {
        let navigator = Navigator()
        navigator.navigate(to: IntRouteKey.self, parameter: 1)
        navigator.navigate(to: IntRouteKey.self, parameter: 2)
        navigator.navigate(to: VoidRouteKey.self)
        navigator.navigate(to: VoidRouteKey.self)

        // Stack: [Int(1), Int(2), Void, Void]; lastIndex of IntRouteKey = 1 → pops 2 above it
        let didPop = navigator.pop(to: IntRouteKey.self)

        #expect(didPop)
        #expect(navigator.path.count == 2)
        #expect(navigator.path.last?.key == IntRouteKey.id)
        #expect(navigator.path.last?.parameter.cast(to: Int.self) == 2)
    }

    @Test("pop(to:) when the key is already the top item returns true without changing the stack")
    func popToKeyAlreadyAtTopIsNoOp() {
        let navigator = Navigator()
        navigator.navigate(to: StringRouteKey.self, parameter: "a")
        navigator.navigate(to: VoidRouteKey.self)
        let didPop = navigator.pop(to: VoidRouteKey.self)
        #expect(didPop)
        #expect(navigator.path.count == 2)
    }

    @Test("pop(to:) returns false and leaves the stack unchanged when the key is absent")
    func popToAbsentKeyReturnsFalse() {
        let navigator = Navigator()
        navigator.navigate(to: StringRouteKey.self, parameter: "a")
        let didPop = navigator.pop(to: VoidRouteKey.self)
        #expect(!didPop)
        #expect(navigator.path.count == 1)
    }

    @Test("popToRoot clears the entire stack")
    func popToRootClears() {
        let navigator = Navigator()
        navigator.navigate(to: VoidRouteKey.self)
        navigator.navigate(to: VoidRouteKey.self)
        navigator.popToRoot()
        #expect(navigator.path.isEmpty)
    }

    @Test("dismiss clears a presented sheet")
    func dismissClearsSheet() {
        let navigator = Navigator()
        navigator.navigate(to: VoidRouteKey.self, style: .sheet)
        navigator.dismiss()
        #expect(navigator.presentingSheet == nil)
    }

    @Test("dismiss clears a presented full-screen cover")
    func dismissClearsFullScreenCover() {
        let navigator = Navigator()
        navigator.navigate(to: VoidRouteKey.self, style: .fullScreenCover)
        navigator.dismiss()
        #expect(navigator.presentingFullScreenCover == nil)
    }

    @Test("dismiss is a no-op when nothing is presented")
    func dismissWhenNothingPresentedIsNoOp() {
        let navigator = Navigator()
        navigator.dismiss()
        #expect(navigator.presentingSheet == nil)
        #expect(navigator.presentingFullScreenCover == nil)
    }

    @Test("setPath replaces the current stack with the resolved intents in order")
    func setPathReplacesStack() {
        let navigator = Navigator()
        navigator.navigate(to: VoidRouteKey.self)

        navigator.setPath([
            NavigationIntent(StringRouteKey.self, parameter: "a"),
            NavigationIntent(IntRouteKey.self, parameter: 1),
        ])

        #expect(navigator.path.count == 2)
        #expect(navigator.path[0].key == StringRouteKey.id)
        #expect(navigator.path[1].key == IntRouteKey.id)
    }

    @Test("setPath([]) clears the stack")
    func setPathWithEmptyArrayClearsStack() {
        let navigator = Navigator()
        navigator.navigate(to: VoidRouteKey.self)
        navigator.setPath([])
        #expect(navigator.path.isEmpty)
    }
}


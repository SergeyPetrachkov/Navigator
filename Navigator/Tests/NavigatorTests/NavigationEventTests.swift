import Testing
import SwiftUI
@testable import Navigator

@MainActor
struct NavigationEventTests {

    @Test("push, sheet, dismiss, overridingRoot, popToRoot, and setPath each emit the right event kind")
    func majorMutationsEmitCorrectEvents() {
        let router = Navigator()
        var events: [NavigationEvent] = []
        router.onEvent = { events.append($0) }

        router.navigate(to: VoidRouteKey.self)
        router.navigate(to: VoidRouteKey.self, style: .sheet)
        router.dismiss()
        router.navigate(to: VoidRouteKey.self, style: .overridingRoot)
        router.popToRoot()
        router.setPath([NavigationIntent(VoidRouteKey.self)])

        #expect(events.count == 6)
        if case .pushed = events[0] {} else { Issue.record("expected .pushed") }
        if case .presented(_, style: .sheet) = events[1] {} else { Issue.record("expected .presented(.sheet)") }
        if case .dismissed = events[2] {} else { Issue.record("expected .dismissed") }
        if case .replacedRoot = events[3] {} else { Issue.record("expected .replacedRoot") }
        if case .poppedToRoot = events[4] {} else { Issue.record("expected .poppedToRoot") }
        if case .replacedPath = events[5] {} else { Issue.record("expected .replacedPath") }
    }

    @Test("setPath([]) emits .replacedPath with an empty array")
    func setPathEmptyEmitsReplacedPath() {
        let router = Navigator()
        var events: [NavigationEvent] = []
        router.onEvent = { events.append($0) }
        router.navigate(to: VoidRouteKey.self)
        events.removeAll()

        router.setPath([])

        #expect(events.count == 1)
        if case .replacedPath(let routes) = events[0] {
            #expect(routes.isEmpty)
        } else {
            Issue.record("expected .replacedPath([])")
        }
    }

    @Test("pop() emits .popped(count: 1)")
    func popEmitsPoppedOne() {
        let router = Navigator()
        var events: [NavigationEvent] = []
        router.onEvent = { events.append($0) }
        router.navigate(to: VoidRouteKey.self)
        events.removeAll()

        router.pop()

        #expect(events.count == 1)
        if case .popped(let count) = events[0] { #expect(count == 1) }
        else { Issue.record("expected .popped(count: 1)") }
    }

    @Test("pop(count:) emits .popped with the actual count removed")
    func popCountEmitsPoppedCount() {
        let router = Navigator()
        var events: [NavigationEvent] = []
        router.onEvent = { events.append($0) }
        router.navigate(to: VoidRouteKey.self)
        router.navigate(to: VoidRouteKey.self)
        events.removeAll()

        router.pop(count: 2)

        #expect(events.count == 1)
        if case .popped(let count) = events[0] { #expect(count == 2) }
        else { Issue.record("expected .popped(count: 2)") }
    }

    @Test("pop(to:) when key is found emits .popped with the number of routes removed")
    func popToEmitsPoppedCount() {
        let router = Navigator()
        var events: [NavigationEvent] = []
        router.onEvent = { events.append($0) }
        router.navigate(to: StringRouteKey.self, parameter: "a")
        router.navigate(to: VoidRouteKey.self)
        router.navigate(to: VoidRouteKey.self)
        events.removeAll()

        router.pop(to: StringRouteKey.self)

        #expect(events.count == 1)
        if case .popped(let count) = events[0] { #expect(count == 2) }
        else { Issue.record("expected .popped(count: 2)") }
    }

    @Test("pop(to:) when the key is already at the top emits no event")
    func popToTopEmitsNoEvent() {
        let router = Navigator()
        var events: [NavigationEvent] = []
        router.onEvent = { events.append($0) }
        router.navigate(to: VoidRouteKey.self)
        events.removeAll()

        router.pop(to: VoidRouteKey.self)

        #expect(events.isEmpty)
    }

    @Test("dismiss when nothing is presented emits no event")
    func dismissWhenNothingPresentedEmitsNoEvent() {
        let router = Navigator()
        var events: [NavigationEvent] = []
        router.onEvent = { events.append($0) }

        router.dismiss()

        #expect(events.isEmpty)
    }
}

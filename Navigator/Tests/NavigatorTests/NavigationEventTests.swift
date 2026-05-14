import Testing
import SwiftUI
@testable import Navigator

@MainActor
struct NavigationEventTests {

    @Test("push, sheet, dismiss, overridingRoot, popToRoot, and setPath each emit the right event kind")
    func majorMutationsEmitCorrectEvents() {
        let navigator = Navigator()
        var events: [NavigationEvent] = []
        navigator.onEvent = { events.append($0) }

        navigator.navigate(to: VoidRouteKey.self)
        navigator.navigate(to: VoidRouteKey.self, style: .sheet)
        navigator.dismiss()
        navigator.navigate(to: VoidRouteKey.self, style: .overridingRoot)
        navigator.popToRoot()
        navigator.setPath([NavigationIntent(VoidRouteKey.self)])

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
        let navigator = Navigator()
        var events: [NavigationEvent] = []
        navigator.onEvent = { events.append($0) }
        navigator.navigate(to: VoidRouteKey.self)
        events.removeAll()

        navigator.setPath([])

        #expect(events.count == 1)
        if case .replacedPath(let routes) = events[0] {
            #expect(routes.isEmpty)
        } else {
            Issue.record("expected .replacedPath([])")
        }
    }

    @Test("pop() emits .popped(count: 1)")
    func popEmitsPoppedOne() {
        let navigator = Navigator()
        var events: [NavigationEvent] = []
        navigator.onEvent = { events.append($0) }
        navigator.navigate(to: VoidRouteKey.self)
        events.removeAll()

        navigator.pop()

        #expect(events.count == 1)
        if case .popped(let count) = events[0] { #expect(count == 1) }
        else { Issue.record("expected .popped(count: 1)") }
    }

    @Test("pop(count:) emits .popped with the actual count removed")
    func popCountEmitsPoppedCount() {
        let navigator = Navigator()
        var events: [NavigationEvent] = []
        navigator.onEvent = { events.append($0) }
        navigator.navigate(to: VoidRouteKey.self)
        navigator.navigate(to: VoidRouteKey.self)
        events.removeAll()

        navigator.pop(count: 2)

        #expect(events.count == 1)
        if case .popped(let count) = events[0] { #expect(count == 2) }
        else { Issue.record("expected .popped(count: 2)") }
    }

    @Test("pop(to:) when key is found emits .popped with the number of routes removed")
    func popToEmitsPoppedCount() {
        let navigator = Navigator()
        var events: [NavigationEvent] = []
        navigator.onEvent = { events.append($0) }
        navigator.navigate(to: StringRouteKey.self, parameter: "a")
        navigator.navigate(to: VoidRouteKey.self)
        navigator.navigate(to: VoidRouteKey.self)
        events.removeAll()

        navigator.pop(to: StringRouteKey.self)

        #expect(events.count == 1)
        if case .popped(let count) = events[0] { #expect(count == 2) }
        else { Issue.record("expected .popped(count: 2)") }
    }

    @Test("pop(to:) when the key is already at the top emits no event")
    func popToTopEmitsNoEvent() {
        let navigator = Navigator()
        var events: [NavigationEvent] = []
        navigator.onEvent = { events.append($0) }
        navigator.navigate(to: VoidRouteKey.self)
        events.removeAll()

        navigator.pop(to: VoidRouteKey.self)

        #expect(events.isEmpty)
    }

    @Test("dismiss when nothing is presented emits no event")
    func dismissWhenNothingPresentedEmitsNoEvent() {
        let navigator = Navigator()
        var events: [NavigationEvent] = []
        navigator.onEvent = { events.append($0) }

        navigator.dismiss()

        #expect(events.isEmpty)
    }
}



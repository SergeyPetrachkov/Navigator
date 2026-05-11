import Testing
import SwiftUI
@testable import Navigator

@MainActor
struct NavigationStyleTests {

    @Test("push appends a route to the path and stores the parameter")
    func pushAppendsRouteWithParameter() {
        let navigator = Navigator()
        navigator.navigate(to: StringRouteKey.self, parameter: "payload")
        #expect(navigator.path.count == 1)
        #expect(navigator.path[0].key == StringRouteKey.id)
        #expect(navigator.path[0].parameter.cast(to: String.self) == "payload")
        #expect(navigator.presentingSheet == nil)
    }

    @Test("sheet sets presentingSheet and leaves the path empty")
    func sheetSetsModal() {
        let navigator = Navigator()
        navigator.navigate(to: VoidRouteKey.self, style: .sheet)
        #expect(navigator.path.isEmpty)
        #expect(navigator.presentingSheet?.key == VoidRouteKey.id)
        #expect(navigator.presentingFullScreenCover == nil)
    }

    @Test("fullScreenCover sets presentingFullScreenCover and leaves the path empty")
    func fullScreenCoverSetsModal() {
        let navigator = Navigator()
        navigator.navigate(to: VoidRouteKey.self, style: .fullScreenCover)
        #expect(navigator.path.isEmpty)
        #if os(iOS)
        #expect(navigator.presentingSheet == nil)
        #expect(navigator.presentingFullScreenCover?.key == VoidRouteKey.id)
        #else
        #expect(navigator.presentingSheet?.key == VoidRouteKey.id)
        #expect(navigator.presentingFullScreenCover == nil)
        #endif
    }

    @Test("overridingRoot replaces the existing stack with a single route")
    func overridingRootReplacesStack() {
        let navigator = Navigator()
        navigator.navigate(to: VoidRouteKey.self)
        navigator.navigate(to: VoidRouteKey.self)
        navigator.navigate(to: VoidRouteKey.self)

        navigator.navigate(to: StringRouteKey.self, parameter: "root", style: .overridingRoot)

        #expect(navigator.path.count == 1)
        #expect(navigator.path[0].key == StringRouteKey.id)
    }

    @Test("presenting a sheet clears any active full-screen cover")
    func sheetClearsFullScreenCover() {
        let navigator = Navigator()
        navigator.navigate(to: VoidRouteKey.self, style: .fullScreenCover)
        navigator.navigate(to: StringRouteKey.self, parameter: "x", style: .sheet)
        #expect(navigator.presentingFullScreenCover == nil)
        #expect(navigator.presentingSheet?.key == StringRouteKey.id)
    }

    @Test("presenting a full-screen cover clears any active sheet")
    func fullScreenCoverClearsSheet() {
        let navigator = Navigator()
        navigator.navigate(to: VoidRouteKey.self, style: .sheet)
        navigator.navigate(to: StringRouteKey.self, parameter: "x", style: .fullScreenCover)
        #if os(iOS)
        #expect(navigator.presentingSheet == nil)
        #expect(navigator.presentingFullScreenCover?.key == StringRouteKey.id)
        #else
        #expect(navigator.presentingSheet?.key == StringRouteKey.id)
        #expect(navigator.presentingFullScreenCover == nil)
        #endif
    }

    @Test("perform(_:) with default push style adds a route built from a NavigationIntent")
    func performPushesIntent() {
        let navigator = Navigator()
        navigator.perform(NavigationIntent(StringRouteKey.self, parameter: "hello"))
        #expect(navigator.path.count == 1)
        #expect(navigator.path[0].key == StringRouteKey.id)
        #expect(navigator.path[0].parameter.cast(to: String.self) == "hello")
    }

    @Test("perform(_:style:) with .sheet style presents the intent as a sheet")
    func performWithSheetStyle() {
        let navigator = Navigator()
        navigator.perform(NavigationIntent(StringRouteKey.self, parameter: "modal"), style: .sheet)
        #expect(navigator.path.isEmpty)
        #expect(navigator.presentingSheet?.key == StringRouteKey.id)
        #expect(navigator.presentingSheet?.parameter.cast(to: String.self) == "modal")
    }
}

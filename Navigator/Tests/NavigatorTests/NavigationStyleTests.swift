import Testing
import SwiftUI
@testable import Navigator

@MainActor
struct NavigationStyleTests {

    @Test("push appends a route to the path and stores the parameter")
    func pushAppendsRouteWithParameter() {
        let router = Navigator()
        router.navigate(to: StringRouteKey.self, parameter: "payload")
        #expect(router.path.count == 1)
        #expect(router.path[0].key == StringRouteKey.id)
        #expect(router.path[0].parameter.cast(to: String.self) == "payload")
        #expect(router.presentingSheet == nil)
    }

    @Test("sheet sets presentingSheet and leaves the path empty")
    func sheetSetsModal() {
        let router = Navigator()
        router.navigate(to: VoidRouteKey.self, style: .sheet)
        #expect(router.path.isEmpty)
        #expect(router.presentingSheet?.key == VoidRouteKey.id)
        #expect(router.presentingFullScreenCover == nil)
    }

    @Test("fullScreenCover sets presentingFullScreenCover and leaves the path empty")
    func fullScreenCoverSetsModal() {
        let router = Navigator()
        router.navigate(to: VoidRouteKey.self, style: .fullScreenCover)
        #expect(router.path.isEmpty)
        #expect(router.presentingSheet == nil)
        #expect(router.presentingFullScreenCover?.key == VoidRouteKey.id)
    }

    @Test("overridingRoot replaces the existing stack with a single route")
    func overridingRootReplacesStack() {
        let router = Navigator()
        router.navigate(to: VoidRouteKey.self)
        router.navigate(to: VoidRouteKey.self)
        router.navigate(to: VoidRouteKey.self)

        router.navigate(to: StringRouteKey.self, parameter: "root", style: .overridingRoot)

        #expect(router.path.count == 1)
        #expect(router.path[0].key == StringRouteKey.id)
    }

    @Test("presenting a sheet clears any active full-screen cover")
    func sheetClearsFullScreenCover() {
        let router = Navigator()
        router.navigate(to: VoidRouteKey.self, style: .fullScreenCover)
        router.navigate(to: StringRouteKey.self, parameter: "x", style: .sheet)
        #expect(router.presentingFullScreenCover == nil)
        #expect(router.presentingSheet?.key == StringRouteKey.id)
    }

    @Test("presenting a full-screen cover clears any active sheet")
    func fullScreenCoverClearsSheet() {
        let router = Navigator()
        router.navigate(to: VoidRouteKey.self, style: .sheet)
        router.navigate(to: StringRouteKey.self, parameter: "x", style: .fullScreenCover)
        #expect(router.presentingSheet == nil)
        #expect(router.presentingFullScreenCover?.key == StringRouteKey.id)
    }

    @Test("perform(_:) with default push style adds a route built from a NavigationIntent")
    func performPushesIntent() {
        let router = Navigator()
        router.perform(NavigationIntent(StringRouteKey.self, parameter: "hello"))
        #expect(router.path.count == 1)
        #expect(router.path[0].key == StringRouteKey.id)
        #expect(router.path[0].parameter.cast(to: String.self) == "hello")
    }

    @Test("perform(_:style:) with .sheet style presents the intent as a sheet")
    func performWithSheetStyle() {
        let router = Navigator()
        router.perform(NavigationIntent(StringRouteKey.self, parameter: "modal"), style: .sheet)
        #expect(router.path.isEmpty)
        #expect(router.presentingSheet?.key == StringRouteKey.id)
        #expect(router.presentingSheet?.parameter.cast(to: String.self) == "modal")
    }
}

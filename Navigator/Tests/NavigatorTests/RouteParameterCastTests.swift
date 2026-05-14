import Navigator
import Testing

private enum PublicStringRouteKey: RouteKey {
    typealias Parameter = String
    static let id = "public.string"
}

@Test(arguments: ["payload", "another string", "", "123"])
func resolvedRouteParameterCastReturnsCorrectString(parameter: String) async throws {
    let route = ResolvedRoute.resolve(PublicStringRouteKey.self, parameter: parameter)

    #expect(route.parameter.cast(to: String.self) == parameter)
}


import BigTechNavigator

public enum AccountRouteKey: RouteKey {
    public typealias Parameter = Void
    public static let id = "account.home"
}

public enum SupportRouteKey: RouteKey {
    public typealias Parameter = String
    public static let id = "account.support.sheet"
}

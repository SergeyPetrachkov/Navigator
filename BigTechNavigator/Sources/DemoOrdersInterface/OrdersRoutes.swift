import Foundation
import BigTechNavigator

public struct DemoOrder: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let status: String

    public init(id: UUID = UUID(), title: String, status: String) {
        self.id = id
        self.title = title
        self.status = status
    }
}

public enum OrdersRouteKey: RouteKey {
    public typealias Parameter = Void
    public static let id = "operations.orders.home"
}

public enum OrderDetailsRouteKey: RouteKey {
    public typealias Parameter = DemoOrder
    public static let id = "operations.orders.details"
}

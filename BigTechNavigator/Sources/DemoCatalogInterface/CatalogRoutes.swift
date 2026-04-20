import Foundation
import BigTechNavigator

public struct DemoProduct: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let price: String

    public init(id: UUID = UUID(), name: String, price: String) {
        self.id = id
        self.name = name
        self.price = price
    }
}

public enum CatalogRouteKey: RouteKey {
    public typealias Parameter = Void
    public static let id = "commerce.catalog.home"
}

public enum ProductDetailsRouteKey: RouteKey {
    public typealias Parameter = DemoProduct
    public static let id = "commerce.catalog.productDetails"
}

public enum CheckoutRouteKey: RouteKey {
    public typealias Parameter = DemoProduct
    public static let id = "commerce.checkout.flow"
}

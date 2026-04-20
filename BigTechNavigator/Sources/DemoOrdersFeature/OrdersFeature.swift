import BigTechNavigator
import DemoOrdersInterface
import SwiftUI

private let sampleOrders: [DemoOrder] = [
    DemoOrder(title: "Order #1042", status: "Packed"),
    DemoOrder(title: "Order #1041", status: "Awaiting pickup"),
    DemoOrder(title: "Order #1039", status: "Delivered"),
]

public struct OrdersRouteModule: AppRouteModule {
    public init() {}

    public func registerRoutes(in registry: RouteRegistry) {
        registry.register(OrdersRouteHandler())
        registry.register(OrderDetailsRouteHandler())
    }
}

private struct OrdersRouteHandler: RouteHandler {
    typealias Key = OrdersRouteKey

    func destination(for parameter: Void) -> some View {
        OrdersScreen(orders: sampleOrders)
    }
}

private struct OrderDetailsRouteHandler: RouteHandler {
    typealias Key = OrderDetailsRouteKey

    func destination(for parameter: DemoOrder) -> some View {
        OrderDetailsScreen(order: parameter)
    }
}

private struct OrdersScreen: View {
    @Environment(Navigator.self) private var router

    let orders: [DemoOrder]

    var body: some View {
        List(orders) { order in
            Button {
                router.navigate(to: OrderDetailsRouteKey.self, parameter: order)
            } label: {
                HStack {
                    Text(order.title)
                    Spacer()
                    Text(order.status)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("Orders")
    }
}

private struct OrderDetailsScreen: View {
    let order: DemoOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(order.title)
                .font(.largeTitle.bold())
            Text("Status: \(order.status)")
                .foregroundStyle(.secondary)
            Text("Orders is a separate module that contributes routes independently.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle("Order Details")
    }
}

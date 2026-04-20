import BigTechNavigator
import DemoAccountInterface
import DemoCatalogInterface
import SwiftUI

private let sampleProducts: [DemoProduct] = [
    DemoProduct(name: "Protein Oats", price: "$12"),
    DemoProduct(name: "Berry Yogurt Bowl", price: "$9"),
    DemoProduct(name: "Recovery Smoothie", price: "$14"),
]

public struct CatalogRouteModule: AppRouteModule {
    public init() {}

    public func registerRoutes(in registry: RouteRegistry) {
        registry.register(CatalogRouteHandler())
        registry.register(ProductDetailsRouteHandler())
        registry.register(CheckoutRouteHandler())
    }
}

private struct CatalogRouteHandler: RouteHandler {
    typealias Key = CatalogRouteKey

    func destination(for parameter: Void) -> some View {
        CatalogScreen(products: sampleProducts)
    }
}

private struct ProductDetailsRouteHandler: RouteHandler {
    typealias Key = ProductDetailsRouteKey

    func destination(for parameter: DemoProduct) -> some View {
        ProductDetailsScreen(product: parameter)
    }
}

private struct CheckoutRouteHandler: RouteHandler {
    typealias Key = CheckoutRouteKey

    func destination(for parameter: DemoProduct) -> some View {
        CheckoutCoordinatorView(product: parameter)
    }
}

private struct CatalogScreen: View {
    @Environment(Navigator.self) private var router

    let products: [DemoProduct]

    var body: some View {
        List {
            Section("Commerce Module") {
                Text("Routes are declared in interface targets and registered by the commerce module.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Products") {
                ForEach(products) { product in
                    Button {
                        router.navigate(to: ProductDetailsRouteKey.self, parameter: product)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(product.name)
                                Text("Owned by DemoCatalogFeature")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(product.price)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Catalog")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Support") {
                    router.navigate(
                        to: SupportRouteKey.self,
                        parameter: "Support opened from Catalog",
                        style: .present
                    )
                }
            }
        }
    }
}

private struct ProductDetailsScreen: View {
    @Environment(Navigator.self) private var router

    let product: DemoProduct

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(product.name)
                .font(.largeTitle.bold())
            Text("Price: \(product.price)")
                .foregroundStyle(.secondary)
            Text("This screen knows only interface route keys. It can open checkout and support without importing those feature implementations.")
                .foregroundStyle(.secondary)

            Button("Start Checkout Flow") {
                router.navigate(to: CheckoutRouteKey.self, parameter: product, style: .present)
            }
            .buttonStyle(.borderedProminent)

            Button("Ask Support") {
                router.navigate(
                    to: SupportRouteKey.self,
                    parameter: "Question about \(product.name)",
                    style: .present
                )
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
        .navigationTitle("Product Details")
    }
}

private enum CheckoutStepRouteKey: RouteKey {
    typealias Parameter = DemoProduct
    static let id = "commerce.checkout.receipt"
}

private struct CheckoutCoordinatorView: View {
    let product: DemoProduct

    @State private var router = Navigator()
    @State private var registry = RouteRegistry()

    init(product: DemoProduct) {
        self.product = product
        _registry = State(initialValue: Self.makeRegistry())
    }

    var body: some View {
        RoutingCoordinatorView(router: router, registry: registry) {
            CheckoutRootScreen(product: product)
        }
        .frame(minWidth: 440, minHeight: 320)
    }

    private static func makeRegistry() -> RouteRegistry {
        let registry = RouteRegistry()
        registry.register(CheckoutReceiptHandler())
        return registry
    }
}

private struct CheckoutRootScreen: View {
    @Environment(Navigator.self) private var router

    let product: DemoProduct

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Checkout Flow")
                .font(.title.bold())
            Text("This is a nested coordinator with its own local router and private route keys.")
                .foregroundStyle(.secondary)
            Text("Purchasing: \(product.name)")
            Button("Place Order") {
                router.navigate(to: CheckoutStepRouteKey.self, parameter: product, style: .overridingRoot)
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
        .navigationTitle("Checkout")
    }
}

private struct CheckoutReceiptHandler: RouteHandler {
    typealias Key = CheckoutStepRouteKey

    func destination(for parameter: DemoProduct) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Receipt")
                .font(.title.bold())
            Text("Order created for \(parameter.name).")
            Text("The nested flow used `.overridingRoot` to replace the checkout step stack.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle("Confirmation")
    }
}

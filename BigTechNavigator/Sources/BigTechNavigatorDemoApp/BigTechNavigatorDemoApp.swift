import BigTechNavigator
import DemoAccountFeature
import DemoAccountInterface
import DemoCatalogFeature
import DemoCatalogInterface
import DemoOrdersFeature
import DemoOrdersInterface
import SwiftUI

@main
struct BigTechNavigatorDemoApp: App {
    @State private var router = Navigator()
    @State private var registry = RouteRegistry()

    init() {
        _registry = State(initialValue: Self.makeRegistry())
    }

    var body: some Scene {
        WindowGroup {
            RoutingCoordinatorView(router: router, registry: registry) {
                DemoHomeView()
            }
            .frame(minWidth: 680, minHeight: 480)
        }
    }

    private static func makeRegistry() -> RouteRegistry {
        let registry = RouteRegistry()
        registry.register([
            CatalogRouteModule(),
            OrdersRouteModule(),
            AccountRouteModule(),
        ])
        return registry
    }
}

private struct DemoHomeView: View {
    @Environment(Navigator.self) private var router

    var body: some View {
        NavigationSplitView {
            List {
                Section("Feature Modules") {
                    Button("Catalog") {
                        router.navigate(to: CatalogRouteKey.self, style: .overridingRoot)
                    }
                    Button("Orders") {
                        router.navigate(to: OrdersRouteKey.self, style: .overridingRoot)
                    }
                    Button("Account") {
                        router.navigate(to: AccountRouteKey.self, style: .overridingRoot)
                    }
                }

                Section("Cross-Module Actions") {
                    Button("Open Support Sheet") {
                        router.navigate(
                            to: SupportRouteKey.self,
                            parameter: "Support opened from the composition root",
                            style: .present
                        )
                    }
                }
            }
            .navigationTitle("Demo App")
        } detail: {
            DemoWelcomeView()
        }
    }
}

private struct DemoWelcomeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("BigTechNavigator Demo")
                .font(.largeTitle.bold())
            Text("This sample keeps route keys in interface targets, route registration in feature modules, and composition as an append-only module list.")
                .foregroundStyle(.secondary)
            Text("Try Catalog -> Product Details -> Checkout to see a nested flow, or Account -> Orders to see root replacement across domains.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(24)
    }
}

import BigTechNavigator
import DemoAccountFeature
import DemoAccountInterface
import DemoCatalogFeature
import DemoCatalogInterface
import DemoOrdersFeature
import DemoOrdersInterface
import SwiftUI

enum AppDeepLinks {

    // this is a dummy example

    static func intent(from url: URL) -> NavigationIntent? {
        NavigationIntent(CatalogRouteKey.self)
    }
}

@main
struct BigTechNavigatorDemoHostApp: App {
    @State private var navigator = Navigator()
    @State private var registry = RouteRegistry()

    init() {
        _registry = State(initialValue: Self.makeRegistry())
    }

    var body: some Scene {
        WindowGroup {
            RoutingCoordinatorView(navigator: navigator, registry: registry) {
                DemoHomeView()
            }
            .onOpenURL { url in
                handle(url)
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                guard let url = activity.webpageURL else { return }
                handle(url)
            }
        }
    }

    private func handle(_ url: URL) {
        guard let intent = AppDeepLinks.intent(from: url) else { return }
        navigator.perform(intent)
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
        NavigationStack {
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
                            parameter: "Support opened from the host app",
                            style: .sheet
                        )
                    }
                }
            }
            .navigationTitle("BigTechNavigator")
        }
    }
}

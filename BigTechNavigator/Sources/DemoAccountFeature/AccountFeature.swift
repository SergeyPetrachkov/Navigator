import BigTechNavigator
import DemoAccountInterface
import DemoOrdersInterface
import SwiftUI

public struct AccountRouteModule: AppRouteModule {
    public init() {}

    public func registerRoutes(in registry: RouteRegistry) {
        registry.register(AccountRouteHandler())
        registry.register(SupportRouteHandler())
    }
}

private struct AccountRouteHandler: RouteHandler {
    typealias Key = AccountRouteKey

    func destination(for parameter: Void) -> some View {
        AccountScreen()
    }
}

private struct SupportRouteHandler: RouteHandler {
    typealias Key = SupportRouteKey

    func destination(for parameter: String) -> some View {
        SupportSheet(context: parameter)
    }
}

private struct AccountScreen: View {
    @Environment(Navigator.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.largeTitle.bold())
            Text("This module can replace the root stack to hand off to another domain flow.")
                .foregroundStyle(.secondary)

            Button("Escalate To Orders Dashboard") {
                router.navigate(to: OrdersRouteKey.self, style: .overridingRoot)
            }
            .buttonStyle(.borderedProminent)

            Button("Open Support") {
                router.navigate(
                    to: SupportRouteKey.self,
                    parameter: "Support opened from Account",
                    style: .sheet
                )
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
        .navigationTitle("Account")
    }
}

private struct SupportSheet: View {
    @Environment(Navigator.self) private var router

    let context: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Support")
                .font(.title.bold())
            Text(context)
            Text("Support is registered by the account module but can be opened from any feature through its interface route key.")
                .foregroundStyle(.secondary)
            Button("Dismiss") {
                router.dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(minWidth: 380, minHeight: 220)
    }
}

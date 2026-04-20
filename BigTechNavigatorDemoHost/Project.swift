import ProjectDescription

let project = Project(
    name: "BigTechNavigatorDemoHost",
    options: .options(
        automaticSchemesOptions: .enabled()
    ),
    packages: [
        .local(path: "../BigTechNavigator"),
        .local(path: "../Navigator"),
    ],
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "CODE_SIGN_STYLE": "Automatic",
            "DEVELOPMENT_TEAM": "",
        ]
    ),
    targets: [
        .target(
            name: "BigTechNavigatorDemoHost",
            destinations: .iOS,
            product: .app,
            bundleId: "com.codex.BigTechNavigatorDemoHost",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
            ]),
            sources: ["Sources/**"],
            dependencies: [
                .package(product: "BigTechNavigator"),
                .package(product: "DemoCatalogInterface"),
                .package(product: "DemoOrdersInterface"),
                .package(product: "DemoAccountInterface"),
                .package(product: "DemoCatalogFeature"),
                .package(product: "DemoOrdersFeature"),
                .package(product: "DemoAccountFeature"),
            ]
        )
    ]
)

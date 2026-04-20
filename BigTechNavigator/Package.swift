// swift-tools-version: 6.2

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .strictMemorySafety(),
    .defaultIsolation(nil)
]

let package = Package(
    name: "BigTechNavigator",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(
            name: "BigTechNavigator",
            targets: ["BigTechNavigator"]
        ),
        .library(
            name: "DemoCatalogInterface",
            targets: ["DemoCatalogInterface"]
        ),
        .library(
            name: "DemoOrdersInterface",
            targets: ["DemoOrdersInterface"]
        ),
        .library(
            name: "DemoAccountInterface",
            targets: ["DemoAccountInterface"]
        ),
        .library(
            name: "DemoCatalogFeature",
            targets: ["DemoCatalogFeature"]
        ),
        .library(
            name: "DemoOrdersFeature",
            targets: ["DemoOrdersFeature"]
        ),
        .library(
            name: "DemoAccountFeature",
            targets: ["DemoAccountFeature"]
        ),
        .executable(
            name: "BigTechNavigatorDemoApp",
            targets: ["BigTechNavigatorDemoApp"]
        ),
    ],
    dependencies: [
        .package(name: "Navigator", path: "../Navigator"),
    ],
    targets: [
        .target(
            name: "BigTechNavigator",
            dependencies: [
                .product(name: "Navigator", package: "Navigator"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "DemoCatalogInterface",
            dependencies: ["BigTechNavigator"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "DemoOrdersInterface",
            dependencies: ["BigTechNavigator"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "DemoAccountInterface",
            dependencies: ["BigTechNavigator"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "DemoCatalogFeature",
            dependencies: [
                "BigTechNavigator",
                "DemoCatalogInterface",
                "DemoAccountInterface",
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "DemoOrdersFeature",
            dependencies: [
                "BigTechNavigator",
                "DemoOrdersInterface",
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "DemoAccountFeature",
            dependencies: [
                "BigTechNavigator",
                "DemoAccountInterface",
                "DemoOrdersInterface",
            ],
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "BigTechNavigatorDemoApp",
            dependencies: [
                "BigTechNavigator",
                "DemoCatalogInterface",
                "DemoOrdersInterface",
                "DemoAccountInterface",
                "DemoCatalogFeature",
                "DemoOrdersFeature",
                "DemoAccountFeature",
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "BigTechNavigatorTests",
            dependencies: ["BigTechNavigator"],
            swiftSettings: swiftSettings
        ),
    ]
)

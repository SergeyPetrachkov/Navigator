// swift-tools-version: 6.2

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .strictMemorySafety(),
    .defaultIsolation(nil)
]

let package = Package(
    name: "Navigator",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(
            name: "Navigator",
            targets: ["Navigator"]
        ),
    ],
    targets: [
        .target(
            name: "Navigator",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "NavigatorTests",
            dependencies: ["Navigator"],
            swiftSettings: swiftSettings
        ),
    ]
)

// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BridgeFlow",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "BridgeFlowCore", targets: ["BridgeFlowCore"]),
        .executable(name: "BridgeFlow", targets: ["BridgeFlow"]),
        .executable(name: "BridgeFlowCoreTests", targets: ["BridgeFlowCoreTests"])
    ],
    targets: [
        .target(
            name: "BridgeFlowCore",
            path: "BridgeFlowCore"
        ),
        .executableTarget(
            name: "BridgeFlow",
            dependencies: ["BridgeFlowCore"],
            path: "BridgeFlow",
            exclude: ["Info.plist"],
            resources: [
                .process("Assets.xcassets"),
                .copy("Resources")
            ]
        ),
        .executableTarget(
            name: "BridgeFlowCoreTests",
            dependencies: ["BridgeFlowCore"],
            path: "Tests/BridgeFlowCoreTests"
        )
    ]
)

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LiquidMusic",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "LiquidMusic",
            targets: ["LiquidMusic"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LiquidMusic",
            dependencies: [],
            path: "LiquidMusic"
        )
    ]
)

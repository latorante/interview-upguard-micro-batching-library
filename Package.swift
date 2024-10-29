// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "micro-batching",
    platforms: [
        .macOS(.v11) // Set the minimum macOS version to 11.0
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MicroBatching",
            targets: ["MicroBatching"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MicroBatching"),
        .testTarget(
            name: "MicroBatchingTests",
            dependencies: ["MicroBatching"]
        ),
    ]
)

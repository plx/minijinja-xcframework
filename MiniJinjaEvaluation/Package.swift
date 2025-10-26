// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MiniJinjaEvaluation",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        // Library product for evaluation and experimentation
        .library(
            name: "MiniJinjaEvaluation",
            targets: ["MiniJinjaEvaluation"]),
    ],
    dependencies: [],
    targets: [
        // Main library target that wraps the MiniJinja C API
        .target(
            name: "MiniJinjaEvaluation",
            dependencies: ["MiniJinjaC"]),

        // Binary target pointing to the locally-built XCFramework
        // This references the output/ directory directly, so rebuilding
        // the XCFramework with `just build` immediately updates this package
        .binaryTarget(
            name: "MiniJinjaC",
            path: "../output/minijinja.xcframework"
        ),

        // Unit tests for evaluating the C API projection and Swift integration
        .testTarget(
            name: "MiniJinjaEvaluationTests",
            dependencies: ["MiniJinjaEvaluation"]),
    ]
)

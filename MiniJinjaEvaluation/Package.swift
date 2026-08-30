// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "MiniJinjaEvaluation",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
    .tvOS(.v15),
    .watchOS(.v8),
    .visionOS(.v1)
  ],
  products: [
    .library(
      name: "MiniJinjaEvaluation",
      targets: ["MiniJinjaEvaluation"]
    )
  ],
  dependencies: [],
  targets: [
    // Binary target pointing to the locally-built XCFramework
    // This references the output/ directory directly, so rebuilding
    // the XCFramework with `just build` immediately updates this package
    .binaryTarget(
      name: "MiniJinjaC",
      path: "../output/MiniJinjaC.xcframework"
    ),
    
    // wrapper & wrapper test:
    .target(
      name: "MiniJinjaEvaluation",
      dependencies: ["MiniJinjaC"]
    ),
    .testTarget(
      name: "MiniJinjaEvaluationTests",
      dependencies: ["MiniJinjaEvaluation"]
    )
  ],
  swiftLanguageModes: [.v6]
)

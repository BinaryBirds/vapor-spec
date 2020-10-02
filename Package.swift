// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "spec",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "Spec", targets: ["Spec"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.30.0")
    ],
    targets: [
        .target(name: "Spec", dependencies: [
            .product(name: "XCTVapor", package: "vapor"),
        ]),
        .testTarget(name: "SpecTests", dependencies: ["Spec"]),
    ]
)

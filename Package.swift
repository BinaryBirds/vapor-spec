// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "vapor-spec",
    platforms: [
       .macOS(.v12),
    ],
    products: [
        .library(name: "VaporSpec", targets: ["VaporSpec"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor", from: "4.77.1")
    ],
    targets: [
        .target(name: "VaporSpec", dependencies: [
            .product(name: "XCTVapor", package: "vapor"),
        ]),
        .testTarget(name: "VaporSpecTests", dependencies: ["VaporSpec"]),
    ]
)

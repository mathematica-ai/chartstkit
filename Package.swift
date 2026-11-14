// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ChartstKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "ChartstKit", targets: ["ChartstKit"]),
    ],
    targets: [
        .target(name: "ChartstKit"),
        .testTarget(name: "ChartstKitTests", dependencies: ["ChartstKit"]),
    ]
)

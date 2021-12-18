// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TestPackage",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "TestPackage",
            targets: ["TestPackage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-package-manager", from: "0.3.0"),
    ],
    targets: [
        .target(
            name: "IndirectCoreRoot",
            dependencies: []),
        .target(
            name: "IndirectCore",
            dependencies: ["IndirectCoreRoot"]),
        .target(
            name: "Core",
            dependencies: ["IndirectCore"]),
        .target(
            name: "TestPackage",
            dependencies: []),
        .testTarget(
            name: "TestPackageTests",
            dependencies: ["TestPackage"])
    ]
)

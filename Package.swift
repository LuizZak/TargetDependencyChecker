// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TargetDependencyChecker",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-syntax", from: "0.50000.0"),
    ],
    targets: [
        // MARK: -
        .target(
            name: "TargetDependencyCheckerLib",
            dependencies: ["SwiftSyntax"]),
        .target(
            name: "TargetDependencyChecker",
            dependencies: ["TargetDependencyCheckerLib"]),
        
        // MARK: - Test targets
        .testTarget(
            name: "TargetDependencyCheckerLibTests",
            dependencies: ["TargetDependencyCheckerLib", "SwiftSyntax"]),
        .testTarget(
            name: "TargetDependencyCheckerTests",
            dependencies: ["TargetDependencyChecker"]),
    ]
)

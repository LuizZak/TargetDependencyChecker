// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "TargetDependencyChecker",
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax", .revision("0.50100.0")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.0.1")
    ],
    targets: [
        // MARK: -
        .target(
            name: "TargetDependencyCheckerLib",
            dependencies: ["SwiftSyntax"]),
        .target(
            name: "TargetDependencyChecker",
            dependencies: ["TargetDependencyCheckerLib", "ArgumentParser"]),
        
        // MARK: - Test targets
        .testTarget(
            name: "TargetDependencyCheckerLibTests",
            dependencies: ["TargetDependencyCheckerLib", "SwiftSyntax"]),
        .testTarget(
            name: "TargetDependencyCheckerTests",
            dependencies: ["TargetDependencyChecker"]),
    ]
)

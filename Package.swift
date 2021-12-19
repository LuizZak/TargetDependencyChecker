// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "TargetDependencyChecker",
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax", .revision("0.50500.0")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
        .package(url: "https://github.com/LuizZak/console.git", .exact("0.8.0")),
    ],
    targets: [
        // MARK: -
        .target(
            name: "TargetDependencyCheckerLib",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "Console", package: "console")
            ]
        ),
        .executableTarget(
            name: "TargetDependencyChecker",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "TargetDependencyCheckerLib"
            ]
        ),
        
        // MARK: - Test targets
        .testTarget(
            name: "TargetDependencyCheckerLibTests",
            dependencies: [
                "TargetDependencyCheckerLib",
                .product(name: "SwiftSyntax", package: "swift-syntax")
            ]
        ),
        .testTarget(
            name: "TargetDependencyCheckerTests",
            dependencies: [
                "TargetDependencyChecker"
            ]
        ),
    ]
)

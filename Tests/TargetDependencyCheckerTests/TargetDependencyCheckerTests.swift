import XCTest
import class Foundation.Bundle

final class TargetDependencyCheckerTests: XCTestCase {
    func testDirectDependencyWarning() throws {
        guard #available(macOS 10.13, *) else {
            return
        }
        
        let binary = productsDirectory.appendingPathComponent("TargetDependencyChecker")
        
        let process = Process()
        process.executableURL = binary
        process.arguments = [
            "--package-path",
            "\(packageRootPath)/TestPackage",
            "--no-color",
        ]
        
        let result = try runProcess(process)
        
        XCTAssertEqual(result.standardOutput, """
            Analyzing package TestPackage...
            !Warning!: TestPackage: Import of framework Core in file Sources/TestPackage/TestPackage.swift:1 is not declared as a dependency, either directly or indirectly, in Package.swift manifest.
            !Warning!: TestPackage: Import of framework SwiftPM in file Sources/TestPackage/TestPackage.swift:2 is not declared as a dependency, either directly or indirectly, in Package.swift manifest.
            Analysis complete! Found 2 issue(s).

            """)
        XCTAssertEqual(result.standardError, "")
        XCTAssertEqual(result.terminationStatus, 0)
    }
    
    func testDirectDependencyWarningXcode() throws {
        guard #available(macOS 10.13, *) else {
            return
        }
        
        let binary = productsDirectory.appendingPathComponent("TargetDependencyChecker")
        
        let process = Process()
        process.executableURL = binary
        process.arguments = [
            "--package-path",
            "\(packageRootPath)/TestPackage",
            "--output-type",
            "xcode",
        ]
        
        let result = try runProcess(process)
        
        XCTAssert(result.standardOutput.contains("""
            Sources/TestPackage/TestPackage.swift:1: error: Import of framework Core in target TestPackage, but dependency is not declared in Package.swift manifest, either directly or indirectly.
            
            """))
        XCTAssertEqual(result.standardError, "")
        XCTAssertEqual(result.terminationStatus, 0)
    }
    
    func testIndirectDependencyWarning() throws {
        guard #available(macOS 10.13, *) else {
            return
        }
        
        let binary = productsDirectory.appendingPathComponent("TargetDependencyChecker")
        
        let process = Process()
        process.executableURL = binary
        process.arguments = [
            "--package-path",
            "\(packageRootPath)/TestPackage",
            "--warn-indirect-dependencies",
            "--no-color",
        ]
        
        let result = try runProcess(process)
        
        XCTAssertEqual(result.standardOutput, """
            Analyzing package TestPackage...
            Indirect-dependency in target Core: Import of framework IndirectCoreRoot in file Sources/Core/Source.swift:2 is not declared as a direct dependency Package.swift manifest.
            !Warning!: TestPackage: Import of framework Core in file Sources/TestPackage/TestPackage.swift:1 is not declared as a dependency, either directly or indirectly, in Package.swift manifest.
            !Warning!: TestPackage: Import of framework SwiftPM in file Sources/TestPackage/TestPackage.swift:2 is not declared as a dependency, either directly or indirectly, in Package.swift manifest.
            Analysis complete! Found 3 issue(s).

            """)
        XCTAssertEqual(result.standardError, "")
        XCTAssertEqual(result.terminationStatus, 0)
    }
    
    func testIndirectDependencyWarningXcode() throws {
        guard #available(macOS 10.13, *) else {
            return
        }
        
        let binary = productsDirectory.appendingPathComponent("TargetDependencyChecker")
        
        let process = Process()
        process.executableURL = binary
        process.arguments = [
            "--package-path",
            "\(packageRootPath)/TestPackage",
            "--warn-indirect-dependencies",
            "--output-type",
            "xcode",
        ]
        
        let result = try runProcess(process)
        
        let lines = result.standardOutput.components(separatedBy: "\n")
        
        XCTAssert(lines.contains { $0.contains("""
            Sources/Core/Source.swift:2: warning: Indirect-dependency: Import of framework IndirectCoreRoot in target Core, but dependency is not declared explicitly in Package.swift manifest.
            """)
        })
        XCTAssert(lines.contains { $0.contains("""
            Sources/TestPackage/TestPackage.swift:1: error: Import of framework Core in target TestPackage, but dependency is not declared in Package.swift manifest, either directly or indirectly.
            """)
        })
        XCTAssertEqual(result.standardError, "")
        XCTAssertEqual(result.terminationStatus, 0)
    }

    func testIgnoreIncludes() throws {
        guard #available(macOS 10.13, *) else {
            return
        }

        let binary = productsDirectory.appendingPathComponent("TargetDependencyChecker")

        let process = Process()
        process.executableURL = binary
        process.arguments = [
            "--package-path",
            "\(packageRootPath)/TestPackage",
            "--no-color",
            "--ignore-includes",
            "SwiftPM",
        ]

        let result = try runProcess(process)

        XCTAssertEqual(result.standardOutput, """
            Analyzing package TestPackage...
            !Warning!: TestPackage: Import of framework Core in file Sources/TestPackage/TestPackage.swift:1 is not declared as a dependency, either directly or indirectly, in Package.swift manifest.
            Analysis complete! Found 1 issue(s).

            """)
        XCTAssertEqual(result.standardError, "")
        XCTAssertEqual(result.terminationStatus, 0)
    }

    func testIgnoreIncludesCommaSeparated() throws {
        guard #available(macOS 10.13, *) else {
            return
        }

        let binary = productsDirectory.appendingPathComponent("TargetDependencyChecker")

        let process = Process()
        process.executableURL = binary
        process.arguments = [
            "--package-path",
            "\(packageRootPath)/TestPackage",
            "--no-color",
            "--ignore-includes",
            "SwiftPM,Core"
        ]

        let result = try runProcess(process)

        XCTAssertEqual(result.standardOutput, """
            Analyzing package TestPackage...
            Analysis complete! Found 0 issue(s).
            
            """)
        XCTAssertEqual(result.standardError, "")
        XCTAssertEqual(result.terminationStatus, 0)
    }

    func testGraphViz_includeIndirect() throws {
        guard #available(macOS 10.13, *) else {
            return
        }

        let binary = productsDirectory.appendingPathComponent("TargetDependencyChecker")

        let process = Process()
        process.executableURL = binary
        process.arguments = [
            "graph",
            "--package-path",
            "\(packageRootPath)/TestPackage",
            "--include-indirect",
        ]

        let result = try runProcess(process)

        XCTAssertEqual(result.standardOutput, """
            digraph {
                graph [rankdir=LR]

                0 [label="Core"]
                1 [label="IndirectCore"]
                2 [label="IndirectCoreRoot"]
                3 [label="TestPackage"]

                0 -> 1
                0 -> 2 [label="@ /Sources/Core/Source.swift"]
                1 -> 2
                3 -> 0 [label="@ /Sources/TestPackage/TestPackage.swift", color=red]
            }

            """)
        XCTAssertEqual(result.standardError, "")
        XCTAssertEqual(result.terminationStatus, 0)
    }

    func testGraphViz_includeTests() throws {
        guard #available(macOS 10.13, *) else {
            return
        }

        let binary = productsDirectory.appendingPathComponent("TargetDependencyChecker")

        let process = Process()
        process.executableURL = binary
        process.arguments = [
            "graph",
            "--package-path",
            "\(packageRootPath)/TestPackage",
            "--include-tests",
        ]

        let result = try runProcess(process)

        XCTAssertEqual(result.standardOutput, """
            digraph {
                graph [rankdir=LR]

                0 [label="Core"]
                1 [label="IndirectCore"]
                2 [label="IndirectCoreRoot"]
                3 [label="TestPackage"]
                4 [label="TestPackageTests"]

                0 -> 1
                1 -> 2
                3 -> 0 [label="@ /Sources/TestPackage/TestPackage.swift", color=red]
                4 -> 3
            }

            """)
        XCTAssertEqual(result.standardError, "")
        XCTAssertEqual(result.terminationStatus, 0)
    }

    func testGraphViz_includeFolderHierarchy() throws {
        guard #available(macOS 10.13, *) else {
            return
        }

        let binary = productsDirectory.appendingPathComponent("TargetDependencyChecker")

        let process = Process()
        process.executableURL = binary
        process.arguments = [
            "graph",
            "--package-path",
            "\(packageRootPath)/TestPackage",
            "--include-tests",
            "--include-folder-hierarchy",
        ]

        let result = try runProcess(process)

        XCTAssertEqual(result.standardOutput, """
            digraph {
                graph [rankdir=LR]

                label = "TestPackage"

                4 [label="TestPackageTests"]

                subgraph cluster_1 {
                    label = "Sources"

                    0 [label="Core"]
                    1 [label="IndirectCore"]
                    2 [label="IndirectCoreRoot"]
                    3 [label="TestPackage"]

                    0 -> 1
                    1 -> 2
                    3 -> 0 [label="@ /Sources/TestPackage/TestPackage.swift", color=red]
                }

                4 -> 3
            }

            """)
        XCTAssertEqual(result.standardError, "")
        XCTAssertEqual(result.terminationStatus, 0)
    }
}

extension TargetDependencyCheckerTests {
    @available(OSX 10.13, *)
    func runProcess(_ process: Process) throws -> ProcessResult {
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = String(data: errorData, encoding: .utf8)
        
        return ProcessResult(standardOutput: output ?? "",
                             standardError: errorOutput ?? "",
                             terminationStatus: process.terminationStatus)
    }
    
    /// Returns path to the built products directory.
    var productsDirectory: URL {
        #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
        #else
        return Bundle.main.bundleURL
        #endif
    }
    
    struct ProcessResult {
        var standardOutput: String
        var standardError: String
        var terminationStatus: Int32
    }
}

let packageRootPath: String = {
    URL(fileURLWithPath: #file)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .path
}()

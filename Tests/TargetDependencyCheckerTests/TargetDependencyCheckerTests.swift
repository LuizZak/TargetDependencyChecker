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
            "\(packageRootPath)/TestPackage"
        ]
        
        let result = try runProcess(process)
        
        XCTAssertEqual(result.standardOutput, """
            Warning: Found import declaration for framework Core in target TestPackage in file Sources/TestPackage/TestPackage.swift, but dependency is not declared in Package.swift manifest, neither directly or indirectly.
            Warning: Found import declaration for framework SwiftPM in target TestPackage in file Sources/TestPackage/TestPackage.swift, but dependency is not declared in Package.swift manifest, neither directly or indirectly.

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
            "xcode"
        ]
        
        let result = try runProcess(process)
        
        XCTAssert(result.standardOutput.contains("""
            Sources/TestPackage/TestPackage.swift:1: warning: Import of framework Core in target TestPackage, but dependency is not declared in Package.swift manifest, neither directly or indirectly.
            
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
            "--warn-indirect-dependencies"
        ]
        
        let result = try runProcess(process)
        
        XCTAssertEqual(result.standardOutput, """
            Indirect-dependency warning: Found import declaration for framework IndirectCoreRoot in target Core in file Sources/Core/Source.swift, but dependency is not declared explicitly in Package.swift manifest.
            Warning: Found import declaration for framework Core in target TestPackage in file Sources/TestPackage/TestPackage.swift, but dependency is not declared in Package.swift manifest, neither directly or indirectly.
            Warning: Found import declaration for framework SwiftPM in target TestPackage in file Sources/TestPackage/TestPackage.swift, but dependency is not declared in Package.swift manifest, neither directly or indirectly.
            
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
            "xcode"
        ]
        
        let result = try runProcess(process)
        
        let lines = result.standardOutput.components(separatedBy: "\n")
        
        XCTAssert(lines.contains { $0.contains("""
            Sources/Core/Source.swift:2: warning: Indirect-dependency: Import of framework IndirectCoreRoot in target Core, but dependency is not declared explicitly in Package.swift manifest.
            """)
        })
        XCTAssert(lines.contains { $0.contains("""
            Sources/TestPackage/TestPackage.swift:1: warning: Import of framework Core in target TestPackage, but dependency is not declared in Package.swift manifest, neither directly or indirectly.
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
            "--ignore-includes",
            "SwiftPM"
        ]

        let result = try runProcess(process)

        XCTAssertEqual(result.standardOutput, """
            Warning: Found import declaration for framework Core in target TestPackage in file Sources/TestPackage/TestPackage.swift, but dependency is not declared in Package.swift manifest, neither directly or indirectly.

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
            "--ignore-includes",
            "SwiftPM,Core"
        ]

        let result = try runProcess(process)

        XCTAssertEqual(result.standardOutput, "")
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
            "--include-indirect"
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
            "--include-tests"
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

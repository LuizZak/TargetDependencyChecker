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
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        XCTAssertEqual(output, """
            Warning: Found import declaration for framework Core in target TestPackage in file Sources/TestPackage/TestPackage.swift, but dependency is not declared in Package.swift manifest, neither directly or indirectly.
            Warning: Found import declaration for framework SwiftPM in target TestPackage in file Sources/TestPackage/TestPackage.swift, but dependency is not declared in Package.swift manifest, neither directly or indirectly.

            """)
        XCTAssertEqual(process.terminationStatus, 0)
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
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        XCTAssert(output?.contains("""
            Sources/TestPackage/TestPackage.swift:1: warning: Import of framework Core in target TestPackage, but dependency is not declared in Package.swift manifest, neither directly or indirectly.
            
            """) == true)
        XCTAssertEqual(process.terminationStatus, 0)
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
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        XCTAssertEqual(output, """
            Indirect-dependency warning: Found import declaration for framework IndirectCoreRoot in target Core in file Sources/Core/Source.swift, but dependency is not declared explicitly in Package.swift manifest.
            Warning: Found import declaration for framework Core in target TestPackage in file Sources/TestPackage/TestPackage.swift, but dependency is not declared in Package.swift manifest, neither directly or indirectly.
            Warning: Found import declaration for framework SwiftPM in target TestPackage in file Sources/TestPackage/TestPackage.swift, but dependency is not declared in Package.swift manifest, neither directly or indirectly.
            
            """)
        XCTAssertEqual(process.terminationStatus, 0)
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
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        let lines = output.components(separatedBy: "\n")
        
        XCTAssert(lines.contains { $0.contains("""
            Sources/Core/Source.swift:2: warning: Indirect-dependency: Import of framework IndirectCoreRoot in target Core, but dependency is not declared explicitly in Package.swift manifest.
            """)
        })
        XCTAssert(lines.contains { $0.contains("""
            Sources/TestPackage/TestPackage.swift:1: warning: Import of framework Core in target TestPackage, but dependency is not declared in Package.swift manifest, neither directly or indirectly.
            """)
        })
        XCTAssertEqual(process.terminationStatus, 0)
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
    
    static var allTests = [
        ("testExample", testDirectDependencyWarning),
    ]
}

let packageRootPath: String = {
    URL(fileURLWithPath: #file)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .path
}()

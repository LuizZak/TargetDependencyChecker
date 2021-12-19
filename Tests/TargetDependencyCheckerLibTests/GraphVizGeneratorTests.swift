import XCTest
@testable import TargetDependencyCheckerLib

class GraphVizGeneratorTests: XCTestCase {
    func testGenerate_mockedPackage() throws {
        let package = PackageBuilder { pack in
            pack.addTarget(name: "CoreLib")
                .addTarget(name: "OtherCoreLib")
                .addTarget(name: "DerivedLib") { derived in
                    derived.addDependency("CoreLib")
                    derived.addDependency("OtherCoreLib")
            }
        }.build()
        let delegate = MockFileManagerDelegate()
        let packageManager = PackageManager(
            package: package,
            packageRootUrl: URL(fileURLWithPath: "/dummy/path", isDirectory: true),
            fileManagerDelegate: delegate
        )

        let sut = GraphVizGenerator(packageManager: packageManager, fileManagerDelegate: delegate)

        let result = try sut.generateFile(includeIndirect: true, includeTests: true, includeFolderHierarchy: false)

        XCTAssertEqual(result, """
        digraph {
            graph [rankdir=LR]

            0 [label="CoreLib"]
            1 [label="DerivedLib"]
            2 [label="OtherCoreLib"]

            1 -> 0
            1 -> 2
        }
        """)
    }

    func _makeHierarchyPackage() -> Package {
        PackageBuilder { pack in
            pack
            .addTarget(name: "Core", path: "Sources/Core")
            .addTarget(name: "FrontendData", path: "Sources/Frontend/FrontendData") {
                $0.addDependency("Core")
            }
            .addTarget(name: "FrontendManager", path: "Sources/Frontend/FrontendManager") {
                $0.addDependency("FrontendData")
                $0.addDependency("Core")
            }
            // Tests
            .addTarget(name: "CoreTests", type: .test) {
                $0.addDependency("Core")
            }
            .addTarget(name: "FrontendDataTests", path: "Tests/Frontend/FrontendDataTests", type: .test) {
                $0.addDependency("FrontendData")
                $0.addDependency("Core")
            }
            .addTarget(name: "FrontendManagerTests", path: "Tests/Frontend/FrontendManagerTests", type: .test) {
                $0.addDependency("FrontendManager")
                $0.addDependency("FrontendData")
                $0.addDependency("Core")
            }
        }.build()
    }
    func testGenerate_mockedPackage_includeFolderHierarchy_true() throws {
        let package = _makeHierarchyPackage()
        let delegate = MockFileManagerDelegate()
        let packageManager = PackageManager(
            package: package,
            packageRootUrl: URL(fileURLWithPath: "/dummy/path", isDirectory: true),
            fileManagerDelegate: delegate
        )

        let sut = GraphVizGenerator(packageManager: packageManager, fileManagerDelegate: delegate)

        let result = try sut.generateFile(includeIndirect: false, includeTests: false, includeFolderHierarchy: true)

        XCTAssertEqual(result, """
        digraph {
            graph [rankdir=LR]

            label = "Sources"

            0 [label="Core"]

            subgraph cluster_1 {
                label = "Frontend"

                1 [label="FrontendData"]
                2 [label="FrontendManager"]

                2 -> 1
            }

            1 -> 0
            2 -> 0
        }
        """)
    }
    func testGenerate_mockedPackage_includeFolderHierarchy_includeTests_true() throws {
        let package = _makeHierarchyPackage()
        let delegate = MockFileManagerDelegate()
        let packageManager = PackageManager(
            package: package,
            packageRootUrl: URL(fileURLWithPath: "/dummy/path", isDirectory: true),
            fileManagerDelegate: delegate
        )

        let sut = GraphVizGenerator(packageManager: packageManager, fileManagerDelegate: delegate)

        let result = try sut.generateFile(includeIndirect: false, includeTests: true, includeFolderHierarchy: true)

        XCTAssertEqual(result, """
        digraph {
            graph [rankdir=LR]

            label = "path"

            subgraph cluster_1 {
                label = "Sources"

                0 [label="Core"]

                subgraph cluster_2 {
                    label = "Frontend"

                    2 [label="FrontendData"]
                    4 [label="FrontendManager"]

                    4 -> 2
                }

                2 -> 0
                4 -> 0
            }

            subgraph cluster_3 {
                label = "Tests"

                1 [label="CoreTests"]

                subgraph cluster_4 {
                    label = "Frontend"

                    3 [label="FrontendDataTests"]
                    5 [label="FrontendManagerTests"]
                }
            }

            1 -> 0
            3 -> 0
            3 -> 2
            5 -> 0
            5 -> 2
            5 -> 4
        }
        """)
    }

    func testGenerate_diskPackage() throws {
        let sut = try generateDiskPackageSut()
        let result = try sut.generateFile(includeIndirect: true, includeTests: true, includeFolderHierarchy: false)

        XCTAssertEqual(result, """
        digraph {
            graph [rankdir=LR]

            0 [label="Core"]
            1 [label="IndirectCore"]
            2 [label="IndirectCoreRoot"]
            3 [label="TestPackage"]
            4 [label="TestPackageTests"]

            0 -> 1
            0 -> 2 [label="@ /Sources/Core/Source.swift"]
            1 -> 2
            3 -> 0 [label="@ /Sources/TestPackage/TestPackage.swift", color=red]
            4 -> 3
        }
        """)
    }

    func testGenerate_diskPackage_includeIndirect_false() throws {
        let sut = try generateDiskPackageSut()
        let result = try sut.generateFile(includeIndirect: false, includeTests: true, includeFolderHierarchy: false)

        XCTAssertEqual(result, """
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
    }

    func testGenerate_diskPackage_includeTests_false() throws {
        let sut = try generateDiskPackageSut()
        let result = try sut.generateFile(includeIndirect: true, includeTests: false, includeFolderHierarchy: false)

        XCTAssertEqual(result, """
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
    }

    // MARK: -

    private func generateDiskPackageSut() throws -> GraphVizGenerator {
        let packageDiscovery = PackageDiscovery(packageUrl: testPackageURL)
        let packageManager = try packageDiscovery.packageManager()
        let delegate = DiskFileManagerDelegate()

        let sut = GraphVizGenerator(packageManager: packageManager, fileManagerDelegate: delegate)

        return sut
    }
}

private class MockFileManagerDelegate: TargetDependencyCheckerLib.FileManagerDelegate {
    func allFilesInUrl(_ url: URL, includePattern: String?, excludePattern: String?) throws -> [URL] {
        return []
    }
    func contentsOfFile(at url: URL, encoding: String.Encoding) throws -> String {
        return ""
    }
    func isDirectory(_ url: URL) -> Bool {
        return !url.lastPathComponent.contains(".swift")
    }
    func writeContents(_ data: Data, toFileURL url: URL) throws {
        
    }
}

let packageRootURL: URL = {
    URL(fileURLWithPath: #file)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
}()

let testPackageURL: URL = {
    packageRootURL
        .appendingPathComponent("TestPackage")
}()

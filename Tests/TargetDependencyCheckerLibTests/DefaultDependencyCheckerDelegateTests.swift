import XCTest
@testable import TargetDependencyCheckerLib

class DefaultDependencyCheckerDelegateTests: XCTestCase {
    var dependencyChecker: DependencyChecker!
    var sut: DefaultDependencyCheckerDelegate!
    
    override func setUp() {
        super.setUp()
        
        dependencyChecker = makeMockDependencyChecker()
        sut = DefaultDependencyCheckerDelegate()
    }
    
    func testDefaultFrameworks() {
        XCTAssert(sut.dependencyChecker(dependencyChecker, isDependencySystemFramework: "Foundation"))
        XCTAssert(sut.dependencyChecker(dependencyChecker, isDependencySystemFramework: "ObjectiveC"))
        XCTAssert(sut.dependencyChecker(dependencyChecker, isDependencySystemFramework: "Darwin"))
        XCTAssert(sut.dependencyChecker(dependencyChecker, isDependencySystemFramework: "Glibc"))
        XCTAssert(sut.dependencyChecker(dependencyChecker, isDependencySystemFramework: "XCTest"))
        XCTAssert(sut.dependencyChecker(dependencyChecker, isDependencySystemFramework: "Dispatch"))
    }
}

func makeMockDependencyChecker() -> DependencyChecker {
    let package = PackageBuilder { pack in
        pack.addTarget(name: "CoreLib")
            .addTarget(name: "OtherCoreLib")
            .addTarget(name: "DerivedLib") { derived in
                derived.addDependency("CoreLib")
                derived.addDependency("OtherCoreLib")
        }
    }.build()
    
    return DependencyChecker(options: .init(),
                             packageManager: PackageManager(package: package,
                                                            packageRootUrl: URL(fileURLWithPath: ""),
                                                            fileManagerDelegate: DiskFileManagerDelegate()),
                             fileManagerDelegate: DiskFileManagerDelegate())
}

class MockFileManagerDelegate: TargetDependencyCheckerLib.FileManagerDelegate {
    func allFilesInUrl(_ url: URL, includePattern: String?, excludePattern: String?) throws -> [URL] {
        return []
    }
    func contentsOfFile(at url: URL, encoding: String.Encoding) throws -> String {
        return ""
    }
    func isDirectory(_ url: URL) -> Bool {
        return false
    }
}

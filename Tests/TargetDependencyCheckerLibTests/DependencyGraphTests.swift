import XCTest
@testable import TargetDependencyCheckerLib

class DependencyGraphTests: XCTestCase {
    func testCreateDependencies() throws {
        let package = PackageBuilder { pack in
            pack.addTarget(name: "CoreLib")
                .addTarget(name: "OtherCoreLib")
                .addTarget(name: "DerivedLib") { derived in
                    derived.addDependency("CoreLib")
                    derived.addDependency("OtherCoreLib")
                }
            }.build()
        
        let sut = try DependencyGraph(package: package)
        
        XCTAssertEqual(sut.dependencies(of: "DerivedLib").count, 2)
        XCTAssertEqual(sut.dependencies(of: "CoreLib").count, 0)
        XCTAssertEqual(sut.dependencies(of: "OtherCoreLib").count, 0)
        XCTAssertEqual(sut.targetsDepending(on: "DerivedLib").count, 0)
        XCTAssertEqual(sut.targetsDepending(on: "CoreLib").count, 1)
        XCTAssertEqual(sut.targetsDepending(on: "OtherCoreLib").count, 1)
    }
    
    func testThrowErrorOnCyclicDependency() {
        let package = PackageBuilder { pack in
            pack.addTarget(name: "LibA") { derived in
                    derived.addDependency("LibB")
                }
                .addTarget(name: "LibB") { derived in
                    derived.addDependency("LibA")
                }
            }.build()
        
        XCTAssertThrowsError(try DependencyGraph(package: package))
    }
    
    func testThrowErrorOnCyclicDependencyDeep() {
        let package = PackageBuilder { pack in
            pack.addTarget(name: "LibA") { derived in
                    derived.addDependency("LibB")
                }
                .addTarget(name: "LibB") { derived in
                    derived.addDependency("LibC")
                }
                .addTarget(name: "LibC") { derived in
                    derived.addDependency("LibA")
                }
            }.build()
        
        XCTAssertThrowsError(try DependencyGraph(package: package))
    }
    
    func testDontThrowErrorOnDiamondDependency() {
        let package = PackageBuilder { pack in
            pack.addTarget(name: "LibA") { derived in
                    derived.addDependencies("LibB", "LibC")
                }
                .addTarget(name: "LibB") { derived in
                    derived.addDependency("LibD")
                }
                .addTarget(name: "LibC") { derived in
                    derived.addDependency("LibD")
                }
                .addTarget(name: "LibD")
            }.build()
        
        XCTAssertNoThrow(try DependencyGraph(package: package))
    }
}

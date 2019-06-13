#if !canImport(ObjectiveC)
import XCTest

extension DependencyGraphTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__DependencyGraphTests = [
        ("testCreateDependencies", testCreateDependencies),
        ("testDontThrowErrorOnDiamondDependency", testDontThrowErrorOnDiamondDependency),
        ("testThrowErrorOnCyclicDependency", testThrowErrorOnCyclicDependency),
        ("testThrowErrorOnCyclicDependencyDeep", testThrowErrorOnCyclicDependencyDeep),
    ]
}

extension MutexTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__MutexTests = [
        ("testMutex", testMutex),
        ("testTryLock", testTryLock),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(DependencyGraphTests.__allTests__DependencyGraphTests),
        testCase(MutexTests.__allTests__MutexTests),
    ]
}
#endif

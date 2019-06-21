import XCTest

import TargetDependencyCheckerLibTests
import TargetDependencyCheckerTests

var tests = [XCTestCaseEntry]()
tests += TargetDependencyCheckerLibTests.__allTests()
tests += TargetDependencyCheckerTests.__allTests()

XCTMain(tests)

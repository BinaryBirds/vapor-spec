import XCTest

import SpecTests

var tests = [XCTestCaseEntry]()
tests += SpecTests.allTests()
XCTMain(tests)

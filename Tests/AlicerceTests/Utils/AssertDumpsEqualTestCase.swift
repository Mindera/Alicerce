import XCTest
@testable import Alicerce

class AssertDumpsEqualTestCase: XCTestCase {

    func test_WithEqualString_ShouldSucceed() {
        let s1 = "test"
        let s2 = "test"

        assertDumpsEqual(s1, s2)
    }

    func test_WithEqualInt_ShouldSucceed() {
        let i1 = 1337
        let i2 = 1337

        assertDumpsEqual(i1, i2)
    }

    func test_WithEqualDate_ShouldSucceed() {
        let d = Date()
        let d1 = d
        let d2 = d

        assertDumpsEqual(d1, d2)
    }

    func test_WithEqualRange_ShouldSucceed() {
        let r1 = 0..<1337
        let r2 = 0..<1337

        assertDumpsEqual(r1, r2)
    }

    func test_WithEqualStringArray_ShouldSucceed() {
        let a1 = ["a", "b", "c"]
        let a2 = ["a", "b", "c"]

        assertDumpsEqual(a1, a2)
    }

    func test_WithEqualIntArray_ShouldSucceed() {
        let a1 = [1, 2, 3]
        let a2 = [1, 2, 3]

        assertDumpsEqual(a1, a2)
    }

    func test_WithEqualDict_ShouldSucceed() {
        let d1 = ["a" : 1, "b" : 2, "c" : 3]
        let d2 = ["a" : 1, "b" : 2, "c" : 3]

        assertDumpsEqual(d1, d2)
    }
    
}

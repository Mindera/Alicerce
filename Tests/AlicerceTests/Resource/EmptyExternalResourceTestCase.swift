import XCTest
import Alicerce

class EmptyExternalResourceTestCase: XCTestCase {

    func testEmpty_WithExternalDataAndDefaultImplementation_ShouldReturnEmptyData() {

        XCTAssert(MockEmptyExternalResource.empty.isEmpty)
    }
}

struct MockEmptyExternalResource: EmptyExternalResource {

    typealias Internal = Void
    typealias External = Data
}

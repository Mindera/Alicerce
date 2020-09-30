import XCTest
@testable import Alicerce

class StackOrchestratorTestCase: XCTestCase {

    typealias FetchValue = StackOrchestrator.FetchValue<Int, String>

    func testValue_WithNetworkFetchValue_ShouldReturnValue() throws {

        let value = FetchValue.network(1337, "🌍")
        XCTAssertEqual(value.value, 1337)
    }

    func testValue_WithPersistenceFetchValue_ShouldReturnValue() throws {

        let value = FetchValue.persistence(1337)
        XCTAssertEqual(value.value, 1337)
    }
}

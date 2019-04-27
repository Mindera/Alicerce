import XCTest
@testable import Alicerce

extension MockNetworkStack: NetworkStore {
    public typealias E = NetworkPersistableStoreError
}

class NetworkStack_NetworkStoreTestCase: XCTestCase {

    private typealias Resource = MockResource<String>
    private typealias NetworkStoreResult = Result<NetworkStoreValue<Resource.Internal>, NetworkPersistableStoreError>

    private enum MockParseError: Error { case 💩 }
    private enum MockOtherError: Error { case 💥 }

    private var networkStack: MockNetworkStack!
    private var testResource: Resource!

    override func setUp() {
        super.setUp()

        networkStack = MockNetworkStack()
        testResource = Resource()
    }

    override func tearDown() {
        networkStack = nil
        testResource = nil

        super.tearDown()
    }

    // MARK: Success tests

    func testFetch_WithSuccessResponse_ShouldCallCompletionClosureWithValue() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: 1.0) }

        testResource.mockDecode = { String(data: $0, encoding: .utf8)! }

        let mockValue = "🎉"
        networkStack.mockData = mockValue.data(using: .utf8)

        let baseURL = URL(string: "http://")!
        let mockResponse = HTTPURLResponse(url: baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        networkStack.mockResponse = mockResponse

        networkStack.fetch(resource: testResource) { (result: NetworkStoreResult) in

            switch result {
            case .success(.network(let value, let response)):
                XCTAssertEqual(value, mockValue)
                XCTAssertEqual(response, mockResponse)
            case .success(let value):
                XCTFail("🔥 received unexpected success 👉 \(value) 😱")
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }

        networkStack.runMockFetch()
    }

    // MARK: Error tests

    func testFetch_WithNetworkFailureError_ShouldThrowNetworkError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: 1.0) }

        let statusCode = 500
        let mockError = NSError(domain: "☠️", code: statusCode, userInfo: nil)

        networkStack.mockError = .url(mockError, nil)

        networkStack.fetch(resource: testResource) { (result: NetworkStoreResult) in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case let .failure(.network(.url(receivedError as NSError, nil))):
                XCTAssertEqual(receivedError, mockError)
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }

        networkStack.runMockFetch()
    }

    func testFetch_WithParseErrorInParse_ShouldThrowParseError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: 1.0) }

        testResource.mockDecode = { _ in throw Parse.Error.json(MockParseError.💩) }

        networkStack.mockData = "🤔".data(using: .utf8)

        networkStack.fetch(resource: testResource) { (result: NetworkStoreResult) in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case .failure(.parse(.json(MockParseError.💩))):
                break // expected error
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }

        networkStack.runMockFetch()
    }

    func testFetch_WithAnyErrorAndCancelledCancelable_ShouldThrowCancelledError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: 1.0) }

        let cancelable = CancelableBag()

        networkStack.mockError = .url(MockOtherError.💥, nil)
        networkStack.beforeFetchCompletionClosure = {
            cancelable.cancel()
        }

        cancelable += networkStack.fetch(resource: testResource) { (result: NetworkStoreResult) in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case .failure(.cancelled(Network.Error.url(MockOtherError.💥, nil)?)):
                 break // expected error
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }

        networkStack.runMockFetch()
    }

    func testFetch_WithOtherErrorInParse_ShouldThrowOtherError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: 1.0) }

        testResource.mockDecode = { _ in throw MockOtherError.💥 }

        networkStack.mockData = "🤔".data(using: .utf8)

        networkStack.fetch(resource: testResource) { (result: NetworkStoreResult) in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case .failure(.other(MockOtherError.💥)):
            break // expected error
            case let .failure(error):
                XCTFail("🔥 received unexpected error 👉 \(error) 😱")
            }

            expectation.fulfill()
        }

        networkStack.runMockFetch()
    }

}

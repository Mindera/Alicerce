import XCTest
import Result
@testable import Alicerce

extension MockNetworkStack: NetworkStore {
    public typealias E = NetworkPersistableStoreError
}

class NetworkStoreTestCase: XCTestCase {

    private enum MockAPIError: Error { case 🔥 }
    private enum MockParseError: Error { case 💩 }
    private enum MockOtherError: Error { case 💥 }

    private struct MockResource: NetworkResource & PersistableResource & StrategyFetchResource & RetryableResource {

        let value: String
        let strategy: StoreFetchStrategy

        let parse: (Data) throws -> String
        let serialize: (String) throws -> Data
        let errorParser: (Data) -> MockAPIError?

        var persistenceKey: Persistence.Key { return value }

        let request = URLRequest(url: URL(string: "http://localhost")!)
        static var empty = Data()

        var retryErrors: [Error]
        var totalRetriedDelay: ResourceRetry.Delay
        var retryPolicies: [ResourceRetry.Policy<Data, URLRequest, URLResponse>]
    }

    private typealias NetworkStoreResult = Result<NetworkStoreValue<MockResource.Local>, NetworkPersistableStoreError>

    private lazy var testResource: MockResource = {
        return MockResource(value: "network",
                            strategy: .networkThenPersistence,
                            parse: { String(data: $0, encoding: .utf8)! },
                            serialize: { $0.data(using: .utf8)! },
                            errorParser: { _ in .🔥 },
                            retryErrors: [],
                            totalRetriedDelay: 0,
                            retryPolicies: [])
    }()

    var networkStack: MockNetworkStack!

    override func setUp() {
        super.setUp()

        networkStack = MockNetworkStack()
    }

    override func tearDown() {
        networkStack = nil

        super.tearDown()
    }

    // MARK: Success tests

    func testFetch_WithSuccessResponse_ShouldCallCompletionClosureWithValue() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: 1.0) }

        let mockValue = "🎉"
        networkStack.mockData = mockValue.data(using: .utf8)

        networkStack.fetch(resource: testResource) { (result: NetworkStoreResult) in

            switch result {
            case .success(.network(let value)):
                XCTAssertEqual(value, mockValue)
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

        networkStack.mockError = .url(mockError)

        networkStack.fetch(resource: testResource) { (result: NetworkStoreResult) in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case let .failure(.network(.url(receivedError as NSError))):
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

        let resource = MockResource(value: "network",
                                    strategy: .networkThenPersistence,
                                    parse: { _ in throw Parse.Error.json(MockParseError.💩) },
                                    serialize: { $0.data(using: .utf8)! },
                                    errorParser: { _ in .🔥 },
                                    retryErrors: [],
                                    totalRetriedDelay: 0,
                                    retryPolicies: [])

        networkStack.mockData = "🤔".data(using: .utf8)

        networkStack.fetch(resource: resource) { (result: NetworkStoreResult) in

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

        networkStack.mockError = .url(MockOtherError.💥)
        networkStack.beforeFetchCompletionClosure = {
            cancelable.cancel()
        }

        cancelable += networkStack.fetch(resource: testResource) { (result: NetworkStoreResult) in

            switch result {
            case .success:
                XCTFail("🔥 should throw an error 🤔")
            case .failure(.cancelled(Network.Error.url(MockOtherError.💥)?)):
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

        let resource = MockResource(value: "network",
                                    strategy: .networkThenPersistence,
                                    parse: { _ in throw MockOtherError.💥 },
                                    serialize: { $0.data(using: .utf8)! },
                                    errorParser: { _ in .🔥 },
                                    retryErrors: [],
                                    totalRetriedDelay: 0,
                                    retryPolicies: [])

        networkStack.mockData = "🤔".data(using: .utf8)

        networkStack.fetch(resource: resource) { (result: NetworkStoreResult) in

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

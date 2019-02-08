import XCTest
import Result
@testable import Alicerce

class NetworkPersistableStoreTestCase: XCTestCase {

    private typealias Resource = MockResource<String>

    private enum TestParseError: Error { case 💩 }

    private let expectationTimeout: TimeInterval = 5
    private let expectationHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("🔥: Test expectation wait timed out: \(error)")
        }
    }

    private var networkStack: MockNetworkStack!
    private var persistenceStack: MockPersistenceStack!

    private var store: NetworkPersistableStore<MockNetworkStack, MockPersistenceStack>!

    private var resource: Resource!

    private let networkValue = "🌍"
    private let persistenceValue = "💾"

    private lazy var networkData = networkValue.data(using: .utf8)!
    private lazy var persistenceData = persistenceValue.data(using: .utf8)!

    private let successResponse = HTTPURLResponse(url: URL(string: "https://mindera.com")!,
                                                  statusCode: 200,
                                                  httpVersion: nil,
                                                  headerFields: nil)!
    private let failureResponse = HTTPURLResponse(url: URL(string: "https://mindera.com")!,
                                                  statusCode: 500,
                                                  httpVersion: nil,
                                                  headerFields: nil)!
    
    override func setUp() {
        super.setUp()

        networkStack = MockNetworkStack()
        persistenceStack = MockPersistenceStack()

        store = NetworkPersistableStore(networkStack: networkStack,
                                        persistenceStack: persistenceStack,
                                        performanceMetrics: nil)

        resource = Resource()
    }
    
    override func tearDown() {
        networkStack = nil
        persistenceStack = nil

        store = nil

        resource = nil

        super.tearDown()
    }

    // MARK: Failure

    //     Network Stack: Error
    // Persistence Stack: No Data
    //            Parser: OK
    //          Strategy: PersistenceThenNetwork
    //   Expected Result: Failed with Network Error
    func testFetch_WithFailingNetwork_ShouldFailWithNetworkError() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        let mockResponse = successResponse

        networkStack.mockError = .noData(response: mockResponse)
        persistenceStack.mockObjectResult = .success(nil)

        resource.mockStrategy = .persistenceThenNetwork

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .network(.noData(response: mockResponse)) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }

        networkStack.runMockFetch()
    }

    //     Network Stack: Error
    // Persistence Stack: No Data
    //            Parser: OK
    //          Strategy: NetworkThenPersistence
    //   Expected Result: Failed with Network Error
    func testFetch_NetworkFirst_WithFailingNetwork_ShouldFailWithNetworkError() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        let mockResponse = successResponse

        networkStack.mockError = .noData(response: mockResponse)
        persistenceStack.mockObjectResult = .success(nil)

        resource.mockStrategy = .networkThenPersistence

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .network(.noData(response: mockResponse)) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }

        networkStack.runMockFetch()
    }

    //     Network Stack: OK
    // Persistence Stack: No Data
    //            Parser: Error
    //          Strategy: PersistenceThenNetwork
    //   Expected Result: Failed with Parser Error
    func testFetch_WithFailingParser_ShouldFailWithParseError() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        networkStack.mockData = networkData
        persistenceStack.mockObjectResult = .success(nil)

        resource.mockStrategy = .persistenceThenNetwork
        resource.mockParse = { _ in throw Parse.Error.json(TestParseError.💩) }

        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .parse(Parse.Error.json(TestParseError.💩)) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }

        networkStack.runMockFetch()
    }

    //     Network Stack: OK
    // Persistence Stack: OK
    //            Parser: Error
    //          Strategy: PersistenceThenNetwork
    //   Expected Result: Failed with Parser Error
    func testFetch_WithCachedDataAndFailingParser_ShouldFail() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        networkStack.mockData = networkData
        persistenceStack.mockObjectResult = .success(persistenceData)

        resource.mockStrategy = .persistenceThenNetwork
        resource.mockParse = { _ in throw Parse.Error.json(TestParseError.💩) }

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .parse(Parse.Error.json(TestParseError.💩)) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }

        networkStack.runMockFetch()
    }

    //     Network Stack: OK
    // Persistence Stack: OK
    //            Parser: Error
    //          Strategy: NetworkThenPersistence
    //   Expected Result: Failed with Parser Error
    func testFetch_NetworkFirst_WithCachedDataAndFailingParser_ShouldFail() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        networkStack.mockData = networkData
        persistenceStack.mockObjectResult = .success(persistenceData)

        resource.mockStrategy = .networkThenPersistence
        resource.mockParse = { _ in throw Parse.Error.json(TestParseError.💩) }

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .parse(Parse.Error.json(TestParseError.💩)) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }

        networkStack.runMockFetch()
    }

    //     Network Stack: Error
    // Persistence Stack: Error
    //            Parser: OK
    //          Strategy: NetworkThenPersistence
    //   Expected Result: Failed with Multiple Error
    func testFetch_NetworkFirst_WithFailingNetworkAndPersistence_ShouldFail() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        let mockResponse = successResponse

        networkStack.mockError = .noData(response: mockResponse)
        persistenceStack.mockObjectResult = .failure(.💥)

        resource.mockStrategy = .networkThenPersistence

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .multiple(let errors) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }

            XCTAssertDumpsEqual(errors, [Network.Error.noData(response: mockResponse), MockPersistenceStack.Error.💥])
        }

        networkStack.runMockFetch()
    }

    //     Network Stack: Error
    // Persistence Stack: Error
    //            Parser: OK
    //          Strategy: PersistenceThenNetwork
    //   Expected Result: Failed with Multiple Error
    func testFetch_PersistenceFirst_WithFailingPersistenceAndNetwork_ShouldFail() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        let mockResponse = successResponse

        networkStack.mockError = .noData(response: mockResponse)
        persistenceStack.mockObjectResult = .failure(.💥)

        resource.mockStrategy = .persistenceThenNetwork

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .multiple(let errors) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }

            XCTAssertDumpsEqual(errors, [MockPersistenceStack.Error.💥, Network.Error.noData(response: mockResponse)])
        }

        networkStack.runMockFetch()
    }

    //     Network Stack: Cancelled Network Error
    // Persistence Stack: No Data
    //            Parser: OK
    //          Strategy: PersistenceThenNetwork
    //   Expected Result: Failed with Cancelled Error
    func testFetch_PersistenceFirst_WithCancelledNetworkFetch_ShouldFailWithCancelledError() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        let cancelable = CancelableBag()
        networkStack.mockError = .url(URLError(.cancelled), response: nil)
        networkStack.beforeFetchCompletionClosure = {
            cancelable.cancel()
        }
        persistenceStack.mockObjectResult = .success(nil)

        resource.mockStrategy = .persistenceThenNetwork

        // When
        cancelable += store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .cancelled(Network.Error.url(URLError.cancelled, response: nil)?) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }

        networkStack.runMockFetch()
    }

    //     Network Stack: Cancelled Network Error
    // Persistence Stack: No Data
    //            Parser: OK
    //          Strategy: NetworkThenPersistence
    //   Expected Result: Failed with Cancelled Error
    func testFetch_NetworkFirst_WithCancelledNetworkFetch_ShouldFailWithCancelledError() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        let cancelable = CancelableBag()
        networkStack.mockError = .badResponse(response: nil)
        networkStack.beforeFetchCompletionClosure = {
            cancelable.cancel()
        }
        persistenceStack.mockObjectResult = .success(nil)

        resource.mockStrategy = .networkThenPersistence

        // When
        cancelable += store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .cancelled(Network.Error.badResponse(nil)?) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }

        networkStack.runMockFetch()
    }

    //     Network Stack: OK
    // Persistence Stack: No Data
    //            Parser: OK
    //          Strategy: PersistenceThenNetwork
    //            Action: Cancel before parse
    //   Expected Result: Failed with Cancelled Error
    func testFetchCancel_BeforeParseUsingPersistenceThenNetwork_ShouldFailWithCancelledError() {
        let fetchExpectation = expectation(description: "testFetch")
        let cancelExpectation = expectation(description: "fetchCancel")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        networkStack.mockData = networkData
        networkStack.mockCancelable.mockCancelClosure = {
            cancelExpectation.fulfill()
        }
        persistenceStack.mockObjectResult = .success(nil)

        resource.mockStrategy = .persistenceThenNetwork

        // When
        let cancelable = store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .cancelled(nil) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }

        // trigger the cancel before the fetch completion closure is invoked
        networkStack.beforeFetchCompletionClosure = {
            cancelable.cancel()
        }

        networkStack.runMockFetch()
    }

    //     Network Stack: OK
    // Persistence Stack: No Data
    //            Parser: OK
    //          Strategy: NetworkThenPersistence
    //            Action: Cancel before parse
    //   Expected Result: Failed with Cancelled Error
    func testFetchCancel_BeforeParseUsingNetworkThenPersistence_ShouldFailWithCancelledError() {
        let fetchExpectation = expectation(description: "testFetch")
        let cancelExpectation = expectation(description: "fetchCancel")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        networkStack.mockData = networkData
        networkStack.mockCancelable.mockCancelClosure = {
            cancelExpectation.fulfill()
        }

        resource.mockStrategy = .networkThenPersistence

        // When
        let cancelable = store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .cancelled(nil) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }

        // trigger the cancel before the fetch completion closure is invoked
        networkStack.beforeFetchCompletionClosure = {
            cancelable.cancel()
        }

        networkStack.runMockFetch()
    }

    //     Network Stack: OK
    // Persistence Stack: No Data
    //            Parser: OK
    //          Strategy: NetworkThenPersistence
    //            Action: Cancel before parse
    //   Expected Result: Failed with Cancelled Error
    func testFetchCancel_AfterFetchErrorUsingNetworkThenPersistence_ShouldFailWithCancelledErrorAndSkipPersistenceCheck() {
        let fetchExpectation = expectation(description: "testFetch")
        let cancelExpectation = expectation(description: "fetchCancel")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        let baseURL = URL(string: "http://")!
        let mockResponse = HTTPURLResponse(url: baseURL,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: nil)!

        networkStack.mockError = .noData(response: mockResponse)
        networkStack.mockCancelable.mockCancelClosure = {
            cancelExpectation.fulfill()
        }

        resource.mockStrategy = .networkThenPersistence

        // When
        let cancelable = store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .cancelled(Network.Error.noData(mockResponse)?) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }

        // trigger the cancel before the fetch completion closure is invoked
        networkStack.beforeFetchCompletionClosure = {
            cancelable.cancel()
        }

        networkStack.runMockFetch()
    }

    //     Network Stack: OK
    // Persistence Stack: OK
    //            Parser: OK
    //          Strategy: PersistenceThenNetwork
    //            Action: Cancel before persist
    //   Expected Result: Failed with Cancelled Error
    func testFetchCancel_BeforePersist_ShouldFailWithCancelledError() {
        let fetchExpectation = expectation(description: "testFetch")
        let cancelExpectation = expectation(description: "fetchCancel")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        networkStack.mockData = networkData
        networkStack.mockCancelable.mockCancelClosure = {
            cancelExpectation.fulfill()
        }

        // closure to cancel the cancelable
        var cancelClosure: (() -> Void)?

        resource.mockStrategy = .persistenceThenNetwork
        resource.mockParse = {
            cancelClosure?()
            return String(data: $0, encoding: .utf8)!
        }

        // When
        let cancelable = store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .cancelled(nil) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }

        // trigger the cancel after the parse closure is invoked
        cancelClosure = {
            cancelable.cancel()
        }

        networkStack.runMockFetch()
    }

    func testClearPersistence_WithFailingRemoveAll_ShouldReturnFailure() {
        let clearExpectation = expectation(description: "testClearPersistence")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        persistenceStack.mockRemoveAllResult = .failure(.💥)

        // When
        store.clearPersistence {
            $0.analysis(ifSuccess: { _ in XCTFail("🔥: unexpected success!") },
                        ifFailure: {
                            guard case .persistence(MockPersistenceStack.Error.💥) = $0
                            else { return XCTFail("🔥: unexpected error \($0)!") }
                        })

            clearExpectation.fulfill()
        }
    }

    // MARK: Success

    //     Network Stack: OK
    // Persistence Stack: No Data
    //            Parser: OK
    //          Strategy: PersistenceThenNetwork
    //   Expected Result: Success from Network: isCached = false
    func testFetch_WithValidData_ShouldSucceed() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        networkStack.mockData = networkData
        persistenceStack.mockObjectResult = .success(nil)

        resource.mockStrategy = .persistenceThenNetwork
        resource.mockParse = {
            XCTAssertEqual($0, self.networkData)
            return self.networkValue
        }

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let value = result.value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertTrue(value.isNetwork)
            XCTAssertEqual(value.value, self.networkValue)
        }

        networkStack.runMockFetch()
    }

    //     Network Stack: OK
    // Persistence Stack: OK
    //            Parser: OK
    //          Strategy: PersistenceThenNetwork
    //   Expected Result: Success from Network: isCached = true
    func testFetch_WithCachedData_ShouldSucceed() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        networkStack.mockData = networkData
        persistenceStack.mockObjectResult = .success(persistenceData)

        resource.mockStrategy = .persistenceThenNetwork

        var count = 0
        resource.mockParse = {
            defer { count += 1 }

            if count == 0 {
                XCTAssertEqual($0, self.persistenceData)
                return self.persistenceValue
            } else {
                XCTAssertEqual($0, self.networkData)
                return self.networkValue
            }
        }

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let value = result.value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertTrue(value.isPersistence)
            XCTAssertEqual(value.value, self.persistenceValue)
        }

        networkStack.runMockFetch()
    }

    //     Network Stack: OK
    // Persistence Stack: Error
    //            Parser: OK
    //          Strategy: PersistenceThenNetwork
    //   Expected Result: Success from Network: isCached = true
    func testFetch_WithValidDataAndFailingPersistenceGet_ShouldSucceed() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        networkStack.mockData = networkData
        persistenceStack.mockObjectResult = .failure(.💥)
        persistenceStack.mockSetObjectResult = .failure(.💥)

        resource.mockStrategy = .persistenceThenNetwork
        resource.mockParse = {
            XCTAssertEqual($0, self.networkData)
            return self.networkValue
        }

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let value = result.value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertTrue(value.isNetwork)
            XCTAssertEqual(value.value, self.networkValue)
        }

        networkStack.runMockFetch()
    }

    //     Network Stack: OK
    // Persistence Stack: OK
    //            Parser: OK
    //          Strategy: NetworkThenPersistence
    //   Expected Result: Success from Network: isCached = false
    func testFetch_withNetworkFirst_ShouldRetrieveFromNetwork() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        networkStack.mockData = networkData
        persistenceStack.mockObjectResult = .success(persistenceData)

        resource.mockStrategy = .networkThenPersistence
        resource.mockParse = {
            XCTAssertEqual($0, self.networkData)
            return self.networkValue
        }

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let value = result.value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertTrue(value.isNetwork)
            XCTAssertEqual(value.value, self.networkValue)
        }

        networkStack.runMockFetch()
    }

    //     Network Stack: Error
    // Persistence Stack: OK
    //            Parser: OK
    //          Strategy: NetworkThenPersistence
    //   Expected Result: Success from Network: isCached = true
    func testFetch_withNetworkFirstAndFailing_ShouldRetrieveFromPersistence() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        let baseURL = URL(string: "http://")!
        let mockResponse = HTTPURLResponse(url: baseURL,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: nil)!

        networkStack.mockError = .noData(response: mockResponse)
        persistenceStack.mockObjectResult = .success(persistenceData)

        resource.mockStrategy = .networkThenPersistence
        resource.mockParse = {
            XCTAssertEqual($0, self.persistenceData)
            return self.persistenceValue
        }

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let value = result.value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertTrue(value.isPersistence)
            XCTAssertEqual(value.value, self.persistenceValue)
        }

        networkStack.runMockFetch()
    }

    //     Network Stack: Error
    // Persistence Stack: OK
    //            Parser: OK
    //          Strategy: PersistenceThenNetwork
    //   Expected Result: Success from Network: isCached = true
    func testFetch_withPersistenceFirst_ShouldRetrieveFromPersistence() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        networkStack.mockData = networkData
        persistenceStack.mockObjectResult = .success(persistenceData)

        resource.mockStrategy = .persistenceThenNetwork

        var count = 0
        resource.mockParse = {
            defer { count += 1 }

            if count == 0 {
                XCTAssertEqual($0, self.persistenceData)
                return self.persistenceValue
            } else {
                XCTAssertEqual($0, self.networkData)
                return self.networkValue
            }
        }

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let value = result.value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertTrue(value.isPersistence)
            XCTAssertEqual(value.value, self.persistenceValue)
        }

        networkStack.runMockFetch()
    }

    //     Network Stack: OK
    // Persistence Stack: Error
    //            Parser: OK
    //          Strategy: PersistenceThenNetwork
    //   Expected Result: Success from Network: isCached = false
    func testFetch_withPersistenceFirstAndFailing_ShouldRetrieveFromNetwork() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        networkStack.mockData = networkData
        persistenceStack.mockObjectResult = .failure(.💥)

        resource.mockStrategy = .persistenceThenNetwork
        resource.mockParse = {
            XCTAssertEqual($0, self.networkData)
            return self.networkValue
        }

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let value = result.value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertTrue(value.isNetwork)
            XCTAssertEqual(value.value, self.networkValue)
        }

        networkStack.runMockFetch()
    }

    //     Network Stack: OK
    // Persistence Stack: Error
    //            Parser: OK
    //          Strategy: PersistenceThenNetwork
    //  Perform. Metrics: defined
    //   Expected Result: Success from Network: isCached = false
    func testFetch_withPersistenceFirstAndFailingAndPerformanceMetrics_ShouldRetrieveFromNetworkAndRecordParseMetric() {
        let fetchExpectation = expectation(description: "testFetch")
        let measureExpectation = expectation(description: "testMeasureParse")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let performanceMetrics = MockNetworkStorePerformanceMetricsTracker()

        store = NetworkPersistableStore(networkStack: networkStack,
                                        persistenceStack: persistenceStack,
                                        performanceMetrics: performanceMetrics)

        // Given
        networkStack.mockData = networkData
        persistenceStack.mockObjectResult = .failure(.💥)

        resource.mockStrategy = .persistenceThenNetwork
        resource.mockParse = {
            XCTAssertEqual($0, self.networkData)
            return self.networkValue
        }

        performanceMetrics.measureSyncInvokedClosure = { identifier, metadata in
            XCTAssertEqual(identifier,
                           performanceMetrics.makeParseIdentifier(for: self.resource, payload: self.networkData))
            XCTAssertDumpsEqual(metadata,
                                [performanceMetrics.modelTypeMetadataKey : "\(Resource.Local.self)",
                                 performanceMetrics.payloadSizeMetadataKey : UInt(self.networkData.count)])
            measureExpectation.fulfill()
        }

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let value = result.value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertTrue(value.isNetwork)
            XCTAssertEqual(value.value, self.networkValue)
        }

        networkStack.runMockFetch()
    }

    func testClearPersistence_WithSuccessRemoveAll_ShouldReturnSuccess() {
        let clearExpectation = expectation(description: "testClearPersistence")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        persistenceStack.mockRemoveAllResult = .success(())

        // When
        store.clearPersistence {
            $0.analysis(ifSuccess: {}, ifFailure: { XCTFail("🔥: unexpected error \($0)!") })
            clearExpectation.fulfill()
        }
    }
}

extension NetworkStoreValue {
    var isNetwork: Bool {
        switch self {
        case .network: return true
        default: return false
        }
    }

    var isPersistence: Bool {
        switch self {
        case .persistence: return true
        default: return false
        }
    }
}

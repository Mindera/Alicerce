import XCTest
import Result
@testable import Alicerce

class NetworkPersistableStoreTestCase: XCTestCase {

    private enum MockAPIError: Error { case 🔥 }
    private enum TestParseError: Error { case 💩 }
    private enum TestSerializeError: Error { case 💩 }
    private enum TestPersistenceError: Error { case 💥 }

    private struct MockResource: NetworkResource, PersistableResource, StrategyFetchResource, RetryableResource {

        let value: String
        let strategy: StoreFetchStrategy
        let parse: (Data) throws -> String
        let serialize: (String) throws -> Data
        let errorParser: (Data) -> MockAPIError?

        var persistenceKey: Persistence.Key {
            return value
        }

        let request = URLRequest(url: URL(string: "http://localhost")!)
        static var empty = Data()

        var retryErrors: [Error]
        var totalRetriedDelay: ResourceRetry.Delay
        var retryPolicies: [ResourceRetry.Policy<Data, URLRequest, URLResponse>]
    }

    private let testValueNetwork = "network"
    private let testValuePersistence = "persistence"

    private lazy var testDataNetwork: Data = {
        return self.testValueNetwork.data(using: .utf8)!
    }()
    private lazy var testDataPersistence: Data = {
        return self.testValuePersistence.data(using: .utf8)!
    }()

    private lazy var testResourceNetworkThenPersistence: MockResource = {
        return MockResource(value: "network",
                            strategy: .networkThenPersistence,
                            parse: { String(data: $0, encoding: .utf8)! },
                            serialize: { $0.data(using: .utf8)! },
                            errorParser: { _ in .🔥 },
                            retryErrors: [],
                            totalRetriedDelay: 0,
                            retryPolicies: [])
    }()
    private lazy var testResourcePersistenceThenNetwork: MockResource = {
        return MockResource(value: "persistence",
                            strategy: .persistenceThenNetwork,
                            parse: { String(data: $0, encoding: .utf8)! },
                            serialize: { $0.data(using: .utf8)! },
                            errorParser: { _ in .🔥 },
                            retryErrors: [],
                            totalRetriedDelay: 0,
                            retryPolicies: [])
    }()

    private let expectationTimeout: TimeInterval = 5
    private let expectationHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("🔥: Test expectation wait timed out: \(error)")
        }
    }

    var networkStack: MockNetworkStack!
    var persistenceStack: MockPersistenceStack!

    var store: NetworkPersistableStore<MockNetworkStack, MockPersistenceStack>!
    
    override func setUp() {
        super.setUp()

        networkStack = MockNetworkStack()
        persistenceStack = MockPersistenceStack()

        store = NetworkPersistableStore(networkStack: networkStack,
                                        persistenceStack: persistenceStack,
                                        performanceMetrics: nil)
    }
    
    override func tearDown() {
        networkStack = nil
        persistenceStack = nil
        store = nil

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
        networkStack.mockError = .noData
        persistenceStack.mockObjectCompletion = { throw Persistence.Error.noObjectForKey }
        let resource = testResourcePersistenceThenNetwork // Parser is OK
        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .network(Network.Error.noData) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }
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
        networkStack.mockError = .noData
        persistenceStack.mockObjectCompletion = { throw Persistence.Error.noObjectForKey }
        let resource = testResourceNetworkThenPersistence // Parser is OK

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .network(Network.Error.noData) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }
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
        networkStack.mockData = testDataNetwork
        persistenceStack.mockObjectCompletion = { throw Persistence.Error.noObjectForKey }
        let resource = MockResource(value: "💥",
                                    strategy: .persistenceThenNetwork,
                                    parse: { _ in throw Parse.Error.json(TestParseError.💩) },
                                    serialize: { _ in throw Serialize.Error.json(TestSerializeError.💩) },
                                    errorParser: { _ in nil },
                                    retryErrors: [],
                                    totalRetriedDelay: 0,
                                    retryPolicies: [])

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
        networkStack.mockData = testDataNetwork
        persistenceStack.mockObjectCompletion = { return self.testDataPersistence }
        let resource = MockResource(value: "💥",
                                    strategy: .persistenceThenNetwork,
                                    parse: { _ in throw Parse.Error.json(TestParseError.💩) },
                                    serialize: { _ in throw Serialize.Error.json(TestSerializeError.💩) },
                                    errorParser: { _ in nil },
                                    retryErrors: [],
                                    totalRetriedDelay: 0,
                                    retryPolicies: [])

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
        networkStack.mockData = testDataNetwork
        persistenceStack.mockObjectCompletion = { return self.testDataPersistence }
        let resource = MockResource(value: "💥",
                                    strategy: .networkThenPersistence,
                                    parse: { _ in throw Parse.Error.json(TestParseError.💩) },
                                    serialize: { _ in throw Serialize.Error.json(TestSerializeError.💩) },
                                    errorParser: { _ in nil },
                                    retryErrors: [],
                                    totalRetriedDelay: 0,
                                    retryPolicies: [])

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
    }

    //     Network Stack: Cancelled Network Error
    // Persistence Stack: No Data
    //            Parser: OK
    //          Strategy: PersistenceThenNetwork
    //   Expected Result: Failed with Cancelled Error
    func testFetch_WithCancelledNetworkFetch_ShouldFailWithCancelledError() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        networkStack.mockError = .url(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled))
        persistenceStack.mockObjectCompletion = { throw Persistence.Error.noObjectForKey }
        let resource = testResourcePersistenceThenNetwork

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .cancelled = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }
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
        networkStack.mockError = .url(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled))
        persistenceStack.mockObjectCompletion = { throw Persistence.Error.noObjectForKey }
        let resource = testResourceNetworkThenPersistence

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .cancelled = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }
    }

    //     Network Stack: OK
    // Persistence Stack: No Data
    //            Parser: OK
    //          Strategy: PersistenceThenNetwork
    //            Action: Cancel before parse
    //   Expected Result: Failed with Cancelled Error
    func testFetchCancel_BeforeParseeUsingPersistenceThenNetwork_ShouldFailWithCancelledError() {
        let fetchExpectation = expectation(description: "testFetch")
        let cancelExpectation = expectation(description: "fetchCancel")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        networkStack.mockData = testDataNetwork
        networkStack.mockCancelable.mockCancelClosure = {
            cancelExpectation.fulfill()
        }
        persistenceStack.mockObjectCompletion = { throw Persistence.Error.noObjectForKey }
        let resource = testResourcePersistenceThenNetwork

        // force fetch to wait for the beforeFetchCompletionClosure to be set
        let semaphore = DispatchSemaphore(value: 0)
        networkStack.queue.async { semaphore.wait() }

        // When
        let cancelable = store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .cancelled = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }

        // trigger the cancel before the fetch completion closure is invoked
        networkStack.beforeFetchCompletionClosure = {
            cancelable.cancel()
        }

        semaphore.signal()
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
        networkStack.mockData = testDataNetwork
        networkStack.mockCancelable.mockCancelClosure = {
            cancelExpectation.fulfill()
        }
        let resource = testResourceNetworkThenPersistence

        // force fetch to wait for the beforeFetchCompletionClosure to be set
        let semaphore = DispatchSemaphore(value: 0)
        networkStack.queue.async { semaphore.wait() }

        // When
        let cancelable = store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .cancelled = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }

        // trigger the cancel before the fetch completion closure is invoked
        networkStack.beforeFetchCompletionClosure = {
            cancelable.cancel()
        }

        semaphore.signal()
    }

    //     Network Stack: OK
    // Persistence Stack: No Data
    //            Parser: OK
    //          Strategy: NetworkThenPersistence
    //            Action: Cancel before parse
    //   Expected Result: Failed with Cancelled Error
    func testFetchCancel_AfterFetchErrorUsingNetworkThenPersistence_ShouldFailWithFetchErrorAndSkipPersistenceCheck() {
        let fetchExpectation = expectation(description: "testFetch")
        let cancelExpectation = expectation(description: "fetchCancel")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // Given
        networkStack.mockError = .noData
        networkStack.mockCancelable.mockCancelClosure = {
            cancelExpectation.fulfill()
        }
        let resource = testResourceNetworkThenPersistence

        // force fetch to wait for the beforeFetchCompletionClosure to be set
        let semaphore = DispatchSemaphore(value: 0)
        networkStack.queue.async { semaphore.wait() }

        // When
        let cancelable = store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .network(.noData) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }

        // trigger the cancel before the fetch completion closure is invoked
        networkStack.beforeFetchCompletionClosure = {
            cancelable.cancel()
        }

        semaphore.signal()
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
        networkStack.mockData = testDataNetwork
        networkStack.mockCancelable.mockCancelClosure = {
            cancelExpectation.fulfill()
        }

        // closure to cancel the cancelable
        var cancelClosure: (() -> Void)?

        let cancellingParse: (Data) -> String = {
            cancelClosure?()
            return String(data: $0, encoding: .utf8)!
        }

        let resource = MockResource(value: self.testValuePersistence,
                                    strategy: .persistenceThenNetwork,
                                    parse: cancellingParse,
                                    serialize: { _ in throw Serialize.Error.json(TestSerializeError.💩) },
                                    errorParser: { _ in nil },
                                    retryErrors: [],
                                    totalRetriedDelay: 0,
                                    retryPolicies: [])



        // force fetch to wait for the cancelClosure to be set
        let semaphore = DispatchSemaphore(value: 0)
        networkStack.queue.async { semaphore.wait() }

        // When
        let cancelable = store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let error = result.error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .cancelled = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }

        // trigger the cancel after the parse closure is invoked
        cancelClosure = {
            cancelable.cancel()
        }

        semaphore.signal()
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
        networkStack.mockData = testDataNetwork
        persistenceStack.mockObjectCompletion = { throw Persistence.Error.noObjectForKey }
        let resource = testResourcePersistenceThenNetwork

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let value = result.value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertTrue(value.isNetwork)
            XCTAssertEqual(value.value, self.testValueNetwork)
        }
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
        networkStack.mockData = testDataNetwork
        persistenceStack.mockObjectCompletion = { return self.testDataPersistence }
        let resource = testResourcePersistenceThenNetwork

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let value = result.value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertTrue(value.isPersistence)
            XCTAssertEqual(value.value, self.testValuePersistence)
        }
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
        networkStack.mockData = testDataNetwork
        persistenceStack.mockObjectCompletion = { throw Persistence.Error.other(TestPersistenceError.💥) }
        persistenceStack.mockSetObjectCompletion = { throw Persistence.Error.other(TestPersistenceError.💥) }
        let resource = testResourcePersistenceThenNetwork

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let value = result.value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertTrue(value.isNetwork)
            XCTAssertEqual(value.value, self.testValueNetwork)
        }
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
        networkStack.mockData = testDataNetwork
        persistenceStack.mockObjectCompletion = { return self.testDataPersistence }
        let resource = testResourceNetworkThenPersistence

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let value = result.value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertTrue(value.isNetwork)
            XCTAssertEqual(value.value, self.testValueNetwork)
        }
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
        networkStack.mockError = .noData
        persistenceStack.mockObjectCompletion = { return self.testDataPersistence }
        let resource = testResourceNetworkThenPersistence

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let value = result.value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertTrue(value.isPersistence)
            XCTAssertEqual(value.value, self.testValuePersistence)
        }
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
        networkStack.mockData = testDataNetwork
        persistenceStack.mockObjectCompletion = { return self.testDataPersistence }
        let resource = testResourcePersistenceThenNetwork

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let value = result.value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertTrue(value.isPersistence)
            XCTAssertEqual(value.value, self.testValuePersistence)
        }
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
        networkStack.mockData = testDataNetwork
        persistenceStack.mockObjectCompletion = { throw Persistence.Error.other(TestPersistenceError.💥) }
        let resource = testResourcePersistenceThenNetwork

        // When
        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            guard let value = result.value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertTrue(value.isNetwork)
            XCTAssertEqual(value.value, self.testValueNetwork)
        }
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
        networkStack.mockData = testDataNetwork
        persistenceStack.mockObjectCompletion = { throw Persistence.Error.other(TestPersistenceError.💥) }
        let resource = testResourcePersistenceThenNetwork

        performanceMetrics.measureSyncInvokedClosure = { identifier, metadata in
            XCTAssertEqual(identifier,
                           performanceMetrics.makeParseIdentifier(for: resource, payload: self.testDataNetwork))
            XCTAssertDumpsEqual(metadata,
                                [performanceMetrics.modelTypeMetadataKey : "\(MockResource.Local.self)",
                                 performanceMetrics.payloadSizeMetadataKey : UInt(self.testDataNetwork.count)])
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
            XCTAssertEqual(value.value, self.testValueNetwork)
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

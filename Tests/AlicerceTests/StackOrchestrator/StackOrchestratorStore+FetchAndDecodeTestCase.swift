import XCTest
@testable import Alicerce

class StackOrchestratorStore_FetchAndDecodeTestCase: XCTestCase {

    private typealias Payload = String

    private struct MockNetworkResource {}
    private enum MockNetworkError: Error { case 🔥 }
    private enum MockPersistenceError: Error { case 🕳 }
    private enum MockDecodeError: Error { case 💣, 🧨 }

    private typealias Response = Int
    private typealias NetworkStack = MockNetworkStack<MockNetworkResource, Payload, Response, MockNetworkError>
    private typealias NetworkDecoding<T> = ModelDecoding<T, Payload, Response>

    private typealias PersistenceKey = String
    private typealias PersistenceStack = MockPersistenceStack<PersistenceKey, Payload, MockPersistenceError>
    private typealias PersistenceDecoding<T> = ModelDecoding<T, Payload, Void>

    private typealias Store = MockStackOrchestratorStore<NetworkStack, PersistenceStack>

    private var networkStack: NetworkStack!
    private var persistenceStack: PersistenceStack!
    private var performanceMetrics: MockStackOrchestratorPerformanceMetricsTracker!

    private var store: Store!

    private var resource: Store.Resource!
    private let networkValue = Network.Value(value: "🌍", response: 1337)
    private let persistenceValue = "💾"

    override func setUpWithError() throws {

        networkStack = .init(
            mockFetch: { resource, completion in
                completion(.failure(.🔥))
                return MockCancelable()
            }
        )

        persistenceStack = .init()

        performanceMetrics = .init()

        store = .init(
            networkStack: networkStack,
            persistenceStack: persistenceStack,
            performanceMetrics: performanceMetrics
        )

        resource = .init(strategy: .networkThenPersistence, networkResource: .init(), persistenceKey: "mock")
    }

    override func tearDownWithError() throws {

        networkStack = nil
        persistenceStack = nil
        performanceMetrics = nil

        store = nil

        resource = nil
    }

    // MARK: - fetchAndDecode

    // MARK: failure

    func testFetchAndDecode_WithFetchFailure_ShouldFailWithFetchErrorAndNotDecodeOrEvict() {

        let fetchExpectation = expectation(description: "testFetch")
        let fetchAndDecodeExpectation = expectation(description: "testFetchAndDecode")
        defer { waitForExpectations(timeout: 1) }

        enum MockError: Error { case 🥔 }

        store.mockFetch = { resource, completion in
            fetchExpectation.fulfill()
            completion(.failure(.cancelled(MockError.🥔)))
            return MockCancelable()
        }

        persistenceStack.mockRemoveObject = { _, completion in
            XCTFail("unexpected removeObject call!")
            completion(.success(()))
        }

        let networkDecoding = NetworkDecoding<Double>.mock { payload, metadata in
            XCTFail("unexpected network decoding!")
            return .failure(MockDecodeError.💣)
        }

        let persistenceDecoding = PersistenceDecoding<Double>.mock { payload, metadata in
            XCTFail("unexpected persistence decoding!")
            return .failure(MockDecodeError.🧨)
        }

        store.fetchAndDecode(
            resource: resource,
            networkDecoding: networkDecoding,
            persistenceDecoding: persistenceDecoding,
            evictOnDecodeFailure: true
        ) { result in

            defer { fetchAndDecodeExpectation.fulfill() }

            switch result {
            case .failure(.fetch(StackOrchestrator.FetchError.cancelled(MockError.🥔?))):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }
    }

    func testFetchAndDecode_WithFetchSuccessFromNetworkAndDecodeFailureAndEnabledEvictOnFailure_ShouldFailWithDecodeErrorAndEvict() {

        let fetchExpectation = expectation(description: "testFetch")
        let decodeExpectation = expectation(description: "testDecode")
        let evictExpectation = expectation(description: "testEvict")
        let fetchAndDecodeExpectation = expectation(description: "testFetchAndDecode")
        defer { waitForExpectations(timeout: 1) }

        store.mockFetch = { resource, completion in
            fetchExpectation.fulfill()
            completion(.success(.network(self.networkValue.value, self.networkValue.response)))
            return MockCancelable()
        }

        persistenceStack.mockRemoveObject = { key, completion in
            evictExpectation.fulfill()
            XCTAssertEqual(key, self.resource.persistenceKey)
            completion(.success(()))
        }

        let networkDecoding = NetworkDecoding<Double>.mock { payload, metadata in
            decodeExpectation.fulfill()
            XCTAssertEqual(payload, self.networkValue.value)
            XCTAssertEqual(metadata, self.networkValue.response)
            return .failure(MockDecodeError.💣)
        }

        let persistenceDecoding = PersistenceDecoding<Double>.mock { payload, metadata in
            XCTFail("unexpected persistence decoding!")
            return .failure(MockDecodeError.🧨)
        }

        store.fetchAndDecode(
            resource: resource,
            networkDecoding: networkDecoding,
            persistenceDecoding: persistenceDecoding,
            evictOnDecodeFailure: true
        ) { result in

            defer { fetchAndDecodeExpectation.fulfill() }

            switch result {
            case .failure(.decode(MockDecodeError.💣)):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }
    }

    func testFetchAndDecode_WithFetchSuccessFromNetworkAndDecodeFailureAndDisabledEvictOnFailure_ShouldFailWithDecodeErrorAndNotEvict() {

        let fetchExpectation = expectation(description: "testFetch")
        let decodeExpectation = expectation(description: "testDecode")
        let fetchAndDecodeExpectation = expectation(description: "testFetchAndDecode")
        defer { waitForExpectations(timeout: 1) }

        store.mockFetch = { resource, completion in
            fetchExpectation.fulfill()
            completion(.success(.network(self.networkValue.value, self.networkValue.response)))
            return MockCancelable()
        }

        persistenceStack.mockRemoveObject = { _, completion in
            XCTFail("unexpected removeObject call!")
            completion(.success(()))
        }

        let networkDecoding = NetworkDecoding<Double>.mock { payload, metadata in
            decodeExpectation.fulfill()
            XCTAssertEqual(payload, self.networkValue.value)
            XCTAssertEqual(metadata, self.networkValue.response)
            return .failure(MockDecodeError.💣)
        }

        let persistenceDecoding = PersistenceDecoding<Double>.mock { payload, metadata in
            XCTFail("unexpected persistence decoding!")
            return .failure(MockDecodeError.🧨)
        }

        store.fetchAndDecode(
            resource: resource,
            networkDecoding: networkDecoding,
            persistenceDecoding: persistenceDecoding,
            evictOnDecodeFailure: false
        ) { result in

            defer { fetchAndDecodeExpectation.fulfill() }

            switch result {
            case .failure(.decode(MockDecodeError.💣)):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }
    }

    func testFetchAndDecode_WithFetchSuccessFromPersistenceAndDecodeFailureAndEnabledEvictOnFailure_ShouldFailWithDecodeErrorAndEvict() {

        let fetchExpectation = expectation(description: "testFetch")
        let decodeExpectation = expectation(description: "testDecode")
        let evictExpectation = expectation(description: "testEvict")
        let fetchAndDecodeExpectation = expectation(description: "testFetchAndDecode")
        defer { waitForExpectations(timeout: 1) }

        store.mockFetch = { resource, completion in
            fetchExpectation.fulfill()
            completion(.success(.persistence(self.persistenceValue)))
            return MockCancelable()
        }

        persistenceStack.mockRemoveObject = { key, completion in
            evictExpectation.fulfill()
            XCTAssertEqual(key, self.resource.persistenceKey)
            completion(.success(()))
        }

        let networkDecoding = NetworkDecoding<Double>.mock { payload, metadata in
            XCTFail("unexpected network decoding!")
            return .failure(MockDecodeError.💣)
        }

        let persistenceDecoding = PersistenceDecoding<Double>.mock { payload, metadata in
            decodeExpectation.fulfill()
            XCTAssertEqual(payload, self.persistenceValue)
            XCTAssertDumpsEqual(metadata, ())
            return .failure(MockDecodeError.🧨)
        }

        store.fetchAndDecode(
            resource: resource,
            networkDecoding: networkDecoding,
            persistenceDecoding: persistenceDecoding,
            evictOnDecodeFailure: true
        ) { result in

            defer { fetchAndDecodeExpectation.fulfill() }

            switch result {
            case .failure(.decode(MockDecodeError.🧨)):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }
    }

    func testFetchAndDecode_WithFetchSuccessFromPersistenceAndDecodeFailureAndDisabledEvictOnFailure_ShouldFailWithDecodeErrorAndNotEvict() {

        let fetchExpectation = expectation(description: "testFetch")
        let decodeExpectation = expectation(description: "testDecode")
        let fetchAndDecodeExpectation = expectation(description: "testFetchAndDecode")
        defer { waitForExpectations(timeout: 1) }

        store.mockFetch = { resource, completion in
            fetchExpectation.fulfill()
            completion(.success(.persistence(self.persistenceValue)))
            return MockCancelable()
        }

        persistenceStack.mockRemoveObject = { _, completion in
            XCTFail("unexpected removeObject call!")
            completion(.success(()))
        }

        let networkDecoding = NetworkDecoding<Double>.mock { payload, metadata in
            XCTFail("unexpected network decoding!")
            return .failure(MockDecodeError.💣)
        }

        let persistenceDecoding = PersistenceDecoding<Double>.mock { payload, metadata in
            decodeExpectation.fulfill()
            XCTAssertEqual(payload, self.persistenceValue)
            XCTAssertDumpsEqual(metadata, ())
            return .failure(MockDecodeError.🧨)
        }

        store.fetchAndDecode(
            resource: resource,
            networkDecoding: networkDecoding,
            persistenceDecoding: persistenceDecoding,
            evictOnDecodeFailure: false
        ) { result in

            defer { fetchAndDecodeExpectation.fulfill() }

            switch result {
            case .failure(.decode(MockDecodeError.🧨)):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }
    }

    // MARK: success

    func testFetchAndDecode_WithFetchSuccessFromNetworkAndDecodeSuccess_ShouldReturnDecodedValue() {
        let fetchExpectation = expectation(description: "testFetch")
        let decodeExpectation = expectation(description: "testDecode")
        let measureDecodeExpectation = expectation(description: "testMeasureDecode")
        let fetchAndDecodeExpectation = expectation(description: "testFetchAndDecode")
        defer { waitForExpectations(timeout: 1) }

        let mockDecodedValue = 1.337

        store.mockFetch = { resource, completion in
            fetchExpectation.fulfill()
            completion(.success(.network(self.networkValue.value, self.networkValue.response)))
            return MockCancelable()
        }

        performanceMetrics.measureSyncInvokedClosure  = { identifier, metadata in
            measureDecodeExpectation.fulfill()
        }

        let networkDecoding = NetworkDecoding<Double>.mock { payload, metadata in
            decodeExpectation.fulfill()
            XCTAssertEqual(payload, self.networkValue.value)
            XCTAssertEqual(metadata, self.networkValue.response)
            return .success(mockDecodedValue)
        }

        let persistenceDecoding = PersistenceDecoding<Double>.mock { payload, metadata in
            XCTFail("unexpected persistence decoding!")
            return .failure(MockDecodeError.🧨)
        }

        store.fetchAndDecode(
            resource: resource,
            networkDecoding: networkDecoding,
            persistenceDecoding: persistenceDecoding,
            evictOnDecodeFailure: true
        ) { result in

            defer { fetchAndDecodeExpectation.fulfill() }

            switch result {
            case .success(.network(mockDecodedValue, self.networkValue.response)):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }
    }

    func testFetchAndDecode_WithFetchSuccessFromPersistenceAndDecodeSuccess_ShouldReturnDecodedValue() {
        let fetchExpectation = expectation(description: "testFetch")
        let decodeExpectation = expectation(description: "testDecode")
        let measureDecodeExpectation = expectation(description: "testMeasureDecode")
        let fetchAndDecodeExpectation = expectation(description: "testFetchAndDecode")
        defer { waitForExpectations(timeout: 1) }

        let mockDecodedValue = 1.337

        store.mockFetch = { resource, completion in
            fetchExpectation.fulfill()
            completion(.success(.persistence(self.persistenceValue)))
            return MockCancelable()
        }

        performanceMetrics.measureSyncInvokedClosure = {_, _ in measureDecodeExpectation.fulfill() }

        let networkDecoding = NetworkDecoding<Double>.mock { payload, metadata in
            XCTFail("unexpected network decoding!")
            return .failure(MockDecodeError.💣)
        }

        let persistenceDecoding = PersistenceDecoding<Double>.mock { payload, metadata in
            decodeExpectation.fulfill()
            XCTAssertEqual(payload, self.persistenceValue)
            XCTAssertDumpsEqual(metadata, ())
            return .success(mockDecodedValue)
        }

        store.fetchAndDecode(
            resource: resource,
            networkDecoding: networkDecoding,
            persistenceDecoding: persistenceDecoding,
            evictOnDecodeFailure: true
        ) { result in

            defer { fetchAndDecodeExpectation.fulfill() }

            switch result {
            case .success(.persistence(mockDecodedValue)):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }
    }

    func testFetchAndDecode_WithFetchSuccessAndDecodeSuccessAndNilPerformanceMetrics_ShouldReturnDecodedValueAndNotMeasureDecode() {
        let fetchExpectation = expectation(description: "testFetch")
        let decodeExpectation = expectation(description: "testDecode")
        let fetchAndDecodeExpectation = expectation(description: "testFetchAndDecode")
        defer { waitForExpectations(timeout: 1) }

        store = .init(networkStack: networkStack, persistenceStack: persistenceStack, performanceMetrics: nil)

        let mockDecodedValue = 1.337

        store.mockFetch = { resource, completion in
            fetchExpectation.fulfill()
            completion(.success(.persistence(self.persistenceValue)))
            return MockCancelable()
        }

        performanceMetrics.measureSyncInvokedClosure = {_, _ in XCTFail("unexpected measure call!") }

        let networkDecoding = NetworkDecoding<Double>.mock { payload, metadata in
            XCTFail("unexpected network decoding!")
            return .failure(MockDecodeError.💣)
        }

        let persistenceDecoding = PersistenceDecoding<Double>.mock { payload, metadata in
            decodeExpectation.fulfill()
            XCTAssertEqual(payload, self.persistenceValue)
            XCTAssertDumpsEqual(metadata, ())
            return .success(mockDecodedValue)
        }

        store.fetchAndDecode(
            resource: resource,
            networkDecoding: networkDecoding,
            persistenceDecoding: persistenceDecoding,
            evictOnDecodeFailure: true
        ) { result in

            defer { fetchAndDecodeExpectation.fulfill() }

            switch result {
            case .success(.persistence(mockDecodedValue)):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }
    }
}

final class MockStackOrchestratorStore<NetworkStack, PersistenceStack>: StackOrchestratorStore
where
    NetworkStack: Alicerce.NetworkStack,
    PersistenceStack: Alicerce.PersistenceStack,
    PersistenceStack.Payload == NetworkStack.Remote
{

    typealias NetworkStack = NetworkStack
    typealias PersistenceStack = PersistenceStack

    var mockFetch: (Resource, @escaping FetchCompletionClosure) -> Cancelable = { _, completion in
        completion(.failure(.cancelled(nil)))
        return MockCancelable()
    }

    var mockClearPersistence: (@escaping (Result<Void, PersistenceStack.Error>) -> Void) -> Void = { completion in
        completion(.success(()))
    }

    var networkStack: NetworkStack
    var persistenceStack: PersistenceStack
    var performanceMetrics: StackOrchestratorPerformanceMetricsTracker?

    init(
        networkStack: NetworkStack,
        persistenceStack: PersistenceStack,
        performanceMetrics: StackOrchestratorPerformanceMetricsTracker? = nil
    ) {

        self.networkStack = networkStack
        self.persistenceStack = persistenceStack
        self.performanceMetrics = performanceMetrics
    }

    func fetch(resource: Resource, completion: @escaping FetchCompletionClosure) -> Cancelable {

        mockFetch(resource, completion)
    }

    func clearPersistence(completion: @escaping (Result<Void, PersistenceStack.Error>) -> Void) {

        mockClearPersistence(completion)
    }
}

extension ModelDecoding {

    static func mock(_ mockDecode: @escaping (Payload, Metadata) -> Result<T, Error>) -> Self {

        .init { payload, metadata in try mockDecode(payload, metadata).get() }
    }
}

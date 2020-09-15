import XCTest
@testable import Alicerce

class StackOrchestratorStoreTestCase: XCTestCase {

    private typealias Payload = String

    private struct MockNetworkResource {}
    private enum MockNetworkError: Error { case 🔥 }
    private enum MockPersistenceError: Error { case 🕳 }

    private typealias Response = Int
    private typealias NetworkStack = MockNetworkStack<MockNetworkResource, Payload, Response, MockNetworkError>

    private typealias PersistenceKey = String
    private typealias PersistenceStack = MockPersistenceStack<PersistenceKey, Payload, MockPersistenceError>

    private typealias Store = StackOrchestrator.Store<NetworkStack, PersistenceStack>

    private var networkStack: NetworkStack!
    private var persistenceStack: PersistenceStack!

    private var store: Store!

    private var resource: Store.Resource!

    private let networkValue = Network.Value(value: "🌍", response: 1337)
    private let persistenceValue = "💾"

    private let successResponse = HTTPURLResponse(
        url: URL(string: "https://mindera.com")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
    )!

    private let failureResponse = HTTPURLResponse(
        url: URL(string: "https://mindera.com")!,
        statusCode: 500,
        httpVersion: nil,
        headerFields: nil
    )!

    override func setUp() {
        super.setUp()

        networkStack = .init(
            mockFetch: { resource, completion in
                completion(.failure(.🔥))
                return MockCancelable()
            }
        )

        persistenceStack = .init()

        store = .init(networkStack: networkStack, persistenceStack: persistenceStack, performanceMetrics: nil)

        resource = .init(strategy: .networkThenPersistence, networkResource: .init(), persistenceKey: "mock")
    }
    
    override func tearDown() {
        networkStack = nil
        persistenceStack = nil

        store = nil

        resource = nil

        super.tearDown()
    }

    // MARK: - fetch

    // MARK: failure

    func testFetch_WithPersistenceThenNetworkAndNoPersistenceHitAndFailingNetwork_ShouldFailWithNetworkError() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: 1) }

        networkStack.mockFetch = { _, completion in
            completion(.failure(.🔥))
            return MockCancelable()
        }
        persistenceStack.mockObject = { _, completion in completion(.success(nil)) }
        resource.strategy = .persistenceThenNetwork

        store.fetch(resource: resource) { result in

            defer { fetchExpectation.fulfill() }

            switch result {
            case .failure(.network(MockNetworkError.🔥)):
                break
            default:
                return XCTFail("🔥: unexpected result: \(result)!")
            }
        }
    }

    func testFetch_WithNetworkThenPersistenceAndNoPersistenceHitAndFailingNetwork_ShouldFailWithNetworkError() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: 1) }

        networkStack.mockFetch = { _, completion in
            completion(.failure(.🔥))
            return MockCancelable()
        }
        persistenceStack.mockObject = { _, completion in completion(.success(nil)) }
        resource.strategy = .networkThenPersistence

        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            switch result {
            case .failure(.network(MockNetworkError.🔥)):
                break
            default:
                return XCTFail("🔥: unexpected result: \(result)!")
            }
        }
    }

    func testFetch_WithNetworkThenPersistenceAndFailingNetworkAndPersistence_ShouldFailWithMultipleErrors() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: 1) }

        networkStack.mockFetch = { _, completion in
            completion(.failure(.🔥))
            return MockCancelable()
        }
        persistenceStack.mockObject = { _, completion in completion(.failure(.🕳)) }
        resource.strategy = .networkThenPersistence

        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            switch result {
            case .failure(.multiple(let errors)):
                XCTAssertDumpsEqual(errors, [MockNetworkError.🔥, MockPersistenceError.🕳])
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }
    }

    func testFetch_PersistenceThenNetworkAndWithFailingPersistenceAndNetwork_ShouldFailWithMultipleErrors() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: 1) }

        networkStack.mockFetch = { _, completion in
            completion(.failure(.🔥))
            return MockCancelable()
        }
        persistenceStack.mockObject = { _, completion in completion(.failure(.🕳)) }
        resource.strategy = .persistenceThenNetwork

        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            switch result {
            case .failure(.multiple(let errors)):
                XCTAssertDumpsEqual(errors, [MockPersistenceError.🕳, MockNetworkError.🔥])
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }
    }

    // MARK: cancel

    func testFetch_WithPersistenceThenNetworkAndCancelledNetworkFetch_ShouldFailWithCancelledError() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: 1) }

        let queue = DispatchQueue(label: "com.mindera.alicerce.mock-network", attributes: .initiallyInactive)
        let cancelable = CancelableBag()

        networkStack.mockFetch = { _, completion in
            cancelable.cancel()
            queue.async { completion(.failure(.🔥)) }
            return MockCancelable()
        }
        persistenceStack.mockObject = { _, completion in completion(.success(nil)) }
        resource.strategy = .persistenceThenNetwork

        cancelable += store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            switch result {
            case .failure(.cancelled(MockNetworkError.🔥?)):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }

        queue.activate()
    }

    func testFetch_WithNetworkThenPersistenceAndCancelledNetworkFetch_ShouldFailWithCancelledError() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: 1) }

        let queue = DispatchQueue(label: "com.mindera.alicerce.mock-network", attributes: .initiallyInactive)
        let cancelable = CancelableBag()

        networkStack.mockFetch = { _, completion in
            cancelable.cancel()
            queue.async { completion(.failure(.🔥)) }
            return MockCancelable()
        }
        persistenceStack.mockObject = { _, completion in completion(.success(nil)) }
        resource.strategy = .networkThenPersistence

        cancelable += store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            switch result {
            case .failure(.cancelled(MockNetworkError.🔥?)):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }

        queue.activate()
    }

    func testFetch_WithPersistenceThenNetworkAndCancelledBeforePersistenceMiss_ShouldFailWithCancelledError() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: 1) }

        let queue = DispatchQueue(label: "com.mindera.alicerce.mock-persistence", attributes: .initiallyInactive)
        let cancelable = CancelableBag()

        networkStack.mockFetch = { _, completion in
            completion(.failure(.🔥))
            return MockCancelable()
        }
        persistenceStack.mockObject = { _, completion in
            cancelable.cancel()
            queue.async { completion(.success(nil)) }
        }
        resource.strategy = .persistenceThenNetwork

        cancelable += store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            switch result {
            case .failure(.cancelled(nil)):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }

        queue.activate()
    }

    func testFetch_WithPersistenceThenNetworkAndCancelledBeforePersistenceHit_ShouldFailWithCancelledError() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: 1) }

        let queue = DispatchQueue(label: "com.mindera.alicerce.mock-persistence", attributes: .initiallyInactive)
        let cancelable = CancelableBag()

        networkStack.mockFetch = { _, completion in
            completion(.failure(.🔥))
            return MockCancelable()
        }
        persistenceStack.mockObject = { _, completion in
            cancelable.cancel()
            queue.async { completion(.success(self.persistenceValue)) }
        }
        resource.strategy = .persistenceThenNetwork

        cancelable += store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            switch result {
            case .failure(.cancelled(nil)):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }

        queue.activate()
    }

    func testFetch_WithPersistenceThenNetworkAndCancelledBeforePersistenceFail_ShouldFailWithCancelledError() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: 1) }

        let queue = DispatchQueue(label: "com.mindera.alicerce.mock-persistence", attributes: .initiallyInactive)
        let cancelable = CancelableBag()

        networkStack.mockFetch = { _, completion in
            completion(.failure(.🔥))
            return MockCancelable()
        }
        persistenceStack.mockObject = { _, completion in
            cancelable.cancel()
            queue.async { completion(.failure(.🕳)) }
        }
        resource.strategy = .persistenceThenNetwork

        cancelable += store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            switch result {
            case .failure(.cancelled(MockPersistenceError.🕳?)):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }

        queue.activate()
    }

    // MARK: success

    func testFetch_WithPersistenceThenNetworkAndPersistenceMissAndNetworkSuccess_ShouldReturnNetworkValue() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: 1) }

        networkStack.mockFetch = { _, completion in
            completion(.success(self.networkValue))
            return MockCancelable()
        }
        persistenceStack.mockObject = { _, completion in completion(.success(nil)) }
        resource.strategy = .persistenceThenNetwork

        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            // Should
            switch result {
            case .success(.network(self.networkValue.value, self.networkValue.response)):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }
    }

    func testFetch_WithPersistenceThenNetworkAndPersistenceHitAndNetworkSuccess_ShoulReturnPersistenceValueAndUpdatePersistence() {
        let fetchExpectation = expectation(description: "testFetch")
        let networkExpectation = expectation(description: "networkFetch")
        let persistenceExpectation = expectation(description: "updatePersistence")
        defer { waitForExpectations(timeout: 1) }

        networkStack.mockFetch = { _, completion in
            networkExpectation.fulfill()
            completion(.success(self.networkValue))
            return MockCancelable()
        }
        persistenceStack.mockObject = { _, completion in completion(.success(self.persistenceValue)) }
        persistenceStack.mockSetObject = { object, key, completion in
            persistenceExpectation.fulfill()
            XCTAssertEqual(object, self.networkValue.value)
            XCTAssertEqual(key, self.resource.persistenceKey)
            completion(.success(()))
        }

        resource.strategy = .persistenceThenNetwork

        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            switch result {
            case .success(.persistence(self.persistenceValue)):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }
    }

    func testFetch_WithPersistenceThenNetworkAndPersistenceHitAndNetworkFailure_ShoulReturnPersistenceValueAndNotUpdatePersistence() {
        let fetchExpectation = expectation(description: "testFetch")
        let networkExpectation = expectation(description: "networkFetch")
        defer { waitForExpectations(timeout: 1) }

        networkStack.mockFetch = { _, completion in
            networkExpectation.fulfill()
            completion(.failure(.🔥))
            return MockCancelable()
        }
        persistenceStack.mockObject = { _, completion in completion(.success(self.persistenceValue)) }
        persistenceStack.mockSetObject = { _, _, completion in
            XCTFail("unexpected setObject call!")
            completion(.failure(.🕳))
        }

        resource.strategy = .persistenceThenNetwork

        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            switch result {
            case .success(.persistence(self.persistenceValue)):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }
    }

    func testFetch_WithPersistenceThenNetworkAndPersistenceFailureAndNetworkSucess_ShouldReturnNetworkValueAndUpdatePersistence() {

        let fetchExpectation = expectation(description: "testFetch")
        let persistenceExpectation = expectation(description: "updatePersistence")
        defer { waitForExpectations(timeout: 1) }

        networkStack.mockFetch = { _, completion in
            completion(.success(self.networkValue))
            return MockCancelable()
        }
        persistenceStack.mockObject = { _, completion in completion(.failure(.🕳)) }
        persistenceStack.mockSetObject = { object, key, completion in
            persistenceExpectation.fulfill()
            XCTAssertEqual(object, self.networkValue.value)
            XCTAssertEqual(key, self.resource.persistenceKey)
            completion(.success(()))
        }

        resource.strategy = .persistenceThenNetwork

        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            switch result {
            case .success(.network(self.networkValue.value, self.networkValue.response)):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }
    }

    func testFetch_WithNetworkThenPersistenceAndNetworkSuccess_ShouldReturnNetworkValueAndUpdatePersistence() {
        let fetchExpectation = expectation(description: "testFetch")
        let persistenceExpectation = expectation(description: "updatePersistence")
        defer { waitForExpectations(timeout: 1) }

        networkStack.mockFetch = { _, completion in
            completion(.success(self.networkValue))
            return MockCancelable()
        }
        persistenceStack.mockObject = { _, completion in
            XCTFail("unexpected object call!")
            completion(.failure(.🕳))
        }
        persistenceStack.mockSetObject = { object, key, completion in
            persistenceExpectation.fulfill()
            XCTAssertEqual(object, self.networkValue.value)
            XCTAssertEqual(key, self.resource.persistenceKey)
            completion(.success(()))
        }

        resource.strategy = .networkThenPersistence

        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            switch result {
            case .success(.network(self.networkValue.value, self.networkValue.response)):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }
    }

    func testFetch_WithNetworkThenPersistenceAndNetworkFailureAndPersistenceHit_ShouldReturnPersistenceValue() {
        let fetchExpectation = expectation(description: "testFetch")
        defer { waitForExpectations(timeout: 1) }

        networkStack.mockFetch = { _, completion in
            completion(.failure(.🔥))
            return MockCancelable()
        }
        persistenceStack.mockObject = { _, completion in
            completion(.success(self.persistenceValue))
        }
        persistenceStack.mockSetObject = { object, key, completion in
            XCTFail("unexpected setObject call!")
            completion(.success(()))
        }

        resource.strategy = .networkThenPersistence

        store.fetch(resource: resource) { result in
            defer { fetchExpectation.fulfill() }

            switch result {
            case .success(.persistence(self.persistenceValue)):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }
    }

    // MARK: - clearPersistence

    func testClearPersistence_WithSuccessRemoveAll_ShouldReturnSuccess() {
        let clearExpectation = expectation(description: "testClearPersistence")
        defer { waitForExpectations(timeout: 1) }

        persistenceStack.mockRemoveAll = { completion in completion(.success(())) }

        store.clearPersistence {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                return XCTFail("🔥 Unexpected error: \(error)!")
            }
            clearExpectation.fulfill()
        }
    }

    func testClearPersistence_WithFailingRemoveAll_ShouldReturnFailure() {
        let clearExpectation = expectation(description: "testClearPersistence")
        defer { waitForExpectations(timeout: 1) }
        

        persistenceStack.mockRemoveAll = { completion in completion(.failure(.🕳)) }

        store.clearPersistence {
            switch $0 {
            case .failure(.🕳):
                break
            default:
                return XCTFail("🔥 Unexpected result: \($0)!")
            }

            clearExpectation.fulfill()
        }
    }
}

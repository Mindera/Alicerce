//
//  StoreTestCase.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 27/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

typealias MockStore<T> = DataStore<T, MockPersistenceStack>

enum MockAPIError: Error {
    case 🔥
}

struct MockResource: NetworkResource, PersistableResource {
    let value: String
    let parser: (Data) throws -> String
    let apiErrorParser: (Data) -> MockAPIError?

    var persistenceKey: Persistence.Key {
        return value
    }

    func toRequest(withBaseURL baseURL: URL) -> URLRequest {
        return URLRequest(url: URL(string: "http://localhost")!)
    }
}

class StoreTestCase: XCTestCase {

    private let testValue = "😎"

    private lazy var testData: Data = {
        return self.testValue.data(using: .utf8)!
    }()

    private lazy var testResource: MockResource = {
        return MockResource(value: self.testValue,
                            parser: { String(data: $0, encoding: .utf8)! },
                            apiErrorParser: { _ in .🔥 })
    }()

    private let expectationTimeout: TimeInterval = 5
    private let expectationHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("🔥: Test expectation wait timed out: \(error)")
        }
    }

    var networkStack: MockNetworkStack!
    var persistenceStack: MockPersistenceStack!

    var store: MockStore<String>!
    
    override func setUp() {
        super.setUp()

        networkStack = MockNetworkStack(mockData: testData, mockError: nil)
        persistenceStack = MockPersistenceStack()

        store = MockStore(networkStack: networkStack,
                          persistenceStack: persistenceStack,
                          metricsConfiguration: nil)
    }
    
    override func tearDown() {
        networkStack = nil
        persistenceStack = nil
        store = nil

        super.tearDown()
    }

    // MARK: Failure

    func testFetch_WithFailingNetwork_ShouldFailWithNetworkError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        networkStack.mockError = .noData

        store.fetch(resource: testResource) { (value, error, isCached) in
            XCTAssertNil(value)
            XCTAssertFalse(isCached)

            defer { expectation.fulfill() }

            guard let error = error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .network(Network.Error.noData) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }
    }

    func testFetch_WithFailingParser_ShouldFailWithParseError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        enum TestParseError: Error { case 💩 }

        let failParseResource = MockResource(value: "💥",
                                             parser: { _ in throw Parse.Error.json(TestParseError.💩) },
                                             apiErrorParser: { _ in nil })

        store.fetch(resource: failParseResource) { (value, error, isCached) in
            XCTAssertNil(value)
            XCTAssertFalse(isCached)

            defer { expectation.fulfill() }

            guard let error = error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .parse(Parse.Error.json(TestParseError.💩)) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }
    }

    func testFetch_WithFailingPersistence_ShouldFailWithParseError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        enum TestParseError: Error { case 💩 }

        let failParseResource = MockResource(value: "💥",
                                             parser: { _ in throw Parse.Error.json(TestParseError.💩) },
                                             apiErrorParser: { _ in nil })

        store.fetch(resource: failParseResource) { (value, error, isCached) in
            XCTAssertNil(value)
            XCTAssertFalse(isCached)

            defer { expectation.fulfill() }

            guard let error = error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .parse(Parse.Error.json(TestParseError.💩)) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }
    }

    func testFetch_WithCachedDataAndFailingParser_ShouldFail() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        enum TestParseError: Error { case 💩 }

        persistenceStack.mockObjectCompletion = { return self.testData }
        let failParseResource = MockResource(value: "💥",
                                             parser: { _ in throw Parse.Error.json(TestParseError.💩) },
                                             apiErrorParser: { _ in nil })

        store.fetch(resource: failParseResource) { (value, error, isCached) in
            XCTAssertNil(value)
            XCTAssertFalse(isCached)

            defer { expectation.fulfill() }

            guard let error = error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .parse(Parse.Error.json(TestParseError.💩)) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }
    }

    func testFetch_WithCancelledNetworkFetch_ShouldFailWithCancelledError() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        networkStack.mockError = .url(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled))

        store.fetch(resource: testResource) { (value, error, isCached) in
            XCTAssertNil(value)
            XCTAssertFalse(isCached)

            defer { expectation.fulfill() }

            guard let error = error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .cancelled = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }
    }

    func testFetchCancel_BeforeParse_ShouldFailWithCancelledError() {
        let expectation = self.expectation(description: "testFetch")
        let expectation2 = self.expectation(description: "fetchCancel")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        networkStack.mockCancelable.mockCancelClosure = {
            expectation2.fulfill()
        }

        // force fetch to wait for the beforeFetchCompletionClosure to be set
        let semaphore = DispatchSemaphore(value: 0)
        networkStack.queue.async(flags: .barrier) { semaphore.wait() }

        let cancelable = store.fetch(resource: testResource) { (value, error, isCached) in
            XCTAssertNil(value)
            XCTAssertFalse(isCached)

            defer { expectation.fulfill() }

            guard let error = error else {
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

    func testFetchCancel_BeforePersist_ShouldFailWithCancelledError() {
        let expectation = self.expectation(description: "testFetch")
        let expectation2 = self.expectation(description: "fetchCancel")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        // closure to cancel the cancelable
        var cancelClosure: (() -> Void)?

        let cancellingParse: (Data) -> String = {
            cancelClosure?()
            return String(data: $0, encoding: .utf8)!
        }

        let cancellingParseResource = MockResource(value: self.testValue,
                                                   parser: cancellingParse,
                                                   apiErrorParser: { _ in nil })

        networkStack.mockCancelable.mockCancelClosure = {
            expectation2.fulfill()
        }

        // force fetch to wait for the cancelClosure to be set
        let semaphore = DispatchSemaphore(value: 0)
        networkStack.queue.async(flags: .barrier) { semaphore.wait() }

        let cancelable = store.fetch(resource: cancellingParseResource) { (value, error, isCached) in
            XCTAssertNil(value)
            XCTAssertFalse(isCached)

            defer { expectation.fulfill() }

            guard let error = error else {
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

    func testFetch_WithValidData_ShouldSucceed() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        store.fetch(resource: testResource) { (value, error, isCached) in
            XCTAssertNil(error)
            XCTAssertFalse(isCached)

            defer { expectation.fulfill() }

            guard let value = value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertEqual(value, self.testValue)
        }
    }

    func testFetch_WithCachedData_ShouldSucceed() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        persistenceStack.mockObjectCompletion = { return self.testData }

        store.fetch(resource: testResource) { (value, error, isCached) in
            XCTAssertNil(error)
            XCTAssertTrue(isCached)

            defer { expectation.fulfill() }

            guard let value = value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertEqual(value, self.testValue)
        }
    }

    func testFetch_WithValidDataAndFailingPersistenceGet_ShouldSucceed() {
        let expectation = self.expectation(description: "testFetch")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        enum TestPersistenceError: Error { case 💥 }

        persistenceStack.mockObjectCompletion = { throw Persistence.Error.other(TestPersistenceError.💥) }
        persistenceStack.mockSetObjectCompletion = { throw Persistence.Error.other(TestPersistenceError.💥) }

        store.fetch(resource: testResource) { (value, error, isCached) in
            XCTAssertNil(error)
            XCTAssertFalse(isCached)

            defer { expectation.fulfill() }

            guard let value = value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertEqual(value, self.testValue)
        }
    }
}

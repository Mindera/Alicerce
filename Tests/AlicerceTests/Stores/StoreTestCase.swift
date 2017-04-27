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

struct MockResource: NetworkResource, PersistableResource {
    let value: String
    let parser: (Data) throws -> String

    var persistenceKey: Persistence.Key {
        return value
    }

    func toRequest(withBaseURL baseURL: URL) -> URLRequest {
        return URLRequest(url: URL(string: "http://localhost")!)
    }
}

class StoreTestCase: XCTestCase {

    let testValue = "😎"

    lazy var testData: Data = {
        return self.testValue.data(using: .utf8)!
    }()

    lazy var testResource: MockResource = {
        return MockResource(value: self.testValue, parser: { String(data: $0, encoding: .utf8)! })
    }()

    var networkStack: MockNetworkStack!
    var persistenceStack: MockPersistenceStack!

    var store: MockStore<String>!
    
    override func setUp() {
        super.setUp()

        networkStack = MockNetworkStack(mockData: testData, mockError: nil)
        persistenceStack = MockPersistenceStack()

        store = MockStore(networkStack: networkStack, persistenceStack: persistenceStack)
    }
    
    override func tearDown() {
        networkStack = nil
        persistenceStack = nil
        store = nil

        super.tearDown()
    }

    // MARK: Failure

    func testFetch_WithFailingNetwork_ShouldFailWithNetworkError() {

        networkStack.mockError = .noData

        store.fetch(resource: testResource) { (value, error, isCached) in
            XCTAssertNil(value)
            XCTAssertFalse(isCached)

            guard let error = error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .network(Network.Error.noData) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }
    }

    func testFetch_WithFailingParser_ShouldFailWithParseError() {

        enum TestParseError: Error { case 💩 }

        let failParseResource = MockResource(value: "💥", parser: { _ in throw Parse.Error.json(TestParseError.💩) })

        store.fetch(resource: failParseResource) { (value, error, isCached) in
            XCTAssertNil(value)
            XCTAssertFalse(isCached)

            guard let error = error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .parse(Parse.Error.json(TestParseError.💩)) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }
    }

    func testFetch_WithFailingPersistence_ShouldFailWithParseError() {

        enum TestParseError: Error { case 💩 }

        let failParseResource = MockResource(value: "💥", parser: { _ in throw Parse.Error.json(TestParseError.💩) })

        store.fetch(resource: failParseResource) { (value, error, isCached) in
            XCTAssertNil(value)
            XCTAssertFalse(isCached)

            guard let error = error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .parse(Parse.Error.json(TestParseError.💩)) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }
    }

    func testFetch_WithCachedDataAndFailingParser_ShouldFail() {

        enum TestParseError: Error { case 💩 }

        persistenceStack.mockObjectCompletion = { return self.testData }
        let failParseResource = MockResource(value: "💥", parser: { _ in throw Parse.Error.json(TestParseError.💩) })

        store.fetch(resource: failParseResource) { (value, error, isCached) in
            XCTAssertNil(value)
            XCTAssertFalse(isCached)

            guard let error = error else {
                return XCTFail("🔥: unexpected success!")
            }

            guard case .parse(Parse.Error.json(TestParseError.💩)) = error else {
                return XCTFail("🔥: unexpected error \(error)!")
            }
        }
    }

    // MARK: Success

    func testFetch_WithValidData_ShouldSucceed() {

        store.fetch(resource: testResource) { (value, error, isCached) in
            XCTAssertNil(error)
            XCTAssertFalse(isCached)

            guard let value = value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertEqual(value, self.testValue)
        }
    }

    func testFetch_WithCachedData_ShouldSucceed() {

        persistenceStack.mockObjectCompletion = { return self.testData }

        store.fetch(resource: testResource) { (value, error, isCached) in
            XCTAssertNil(error)
            XCTAssertTrue(isCached)

            guard let value = value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertEqual(value, self.testValue)
        }
    }

    func testFetch_WithValidDataAndFailingPersistenceGet_ShouldSucceed() {

        enum TestPersistenceError: Error { case 💥 }

        persistenceStack.mockObjectCompletion = { _ in throw Persistence.Error.other(TestPersistenceError.💥) }
        persistenceStack.mockSetObjectCompletion = { _ in throw Persistence.Error.other(TestPersistenceError.💥) }

        store.fetch(resource: testResource) { (value, error, isCached) in
            XCTAssertNil(error)
            XCTAssertFalse(isCached)

            guard let value = value else {
                return XCTFail("🔥: missing value!")
            }

            XCTAssertEqual(value, self.testValue)
        }
    }
}

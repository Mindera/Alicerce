import XCTest
@testable import Alicerce

class NetworkStackTestCase: XCTestCase {

    private typealias Resource = UUID
    private typealias Payload = String
    private typealias Response = Int

    private enum MockNetworkError: Error { case 🔥 }
    private enum MockDecodeError: Error { case 💣, 🧨 }

    private typealias NetworkStack = MockNetworkStack<Resource, Payload, Response, MockNetworkError>
    private typealias NetworkDecoding<T> = ModelDecoding<T, Payload, Response>

    private var stack: NetworkStack!

    private var resource: Resource!
    private let networkValue = Network.Value(value: "🌍", response: 1337)

    override func setUpWithError() throws {

        stack = NetworkStack { resource, completion in
            completion(.failure(.🔥))
            return MockCancelable()
        }

        resource = .init()
    }

    override func tearDownWithError() throws {

        stack = nil
        resource = nil
    }

    // MARK: - fetchAndDecode

    // MARK: failure

    func testFetchAndDecode_WithFetchFailure_ShouldFailWithFetchError() {

        let fetchExpectation = expectation(description: "testFetch")
        let fetchAndDecodeExpectation = expectation(description: "testFetchAndDecode")
        defer { waitForExpectations(timeout: 1) }

        enum MockError: Error { case 🥔 }

        stack.mockFetch = { resource, completion in
            fetchExpectation.fulfill()
            XCTAssertEqual(resource, self.resource)
            completion(.failure(.🔥))
            return MockCancelable()
        }

        let decoding = NetworkDecoding<Double>.mock { payload, metadata in
            XCTFail("unexpected decoding!")
            return .failure(MockDecodeError.💣)
        }

        stack.fetchAndDecode(resource: resource, decoding: decoding) { result in

            defer { fetchAndDecodeExpectation.fulfill() }

            switch result {
            case .failure(.fetch(MockNetworkError.🔥)):
                break
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }
    }

    func testFetchAndDecode_WithFetchSuccessFromNetworkAndDecodeFailure_ShouldFailWithDecodeError() {

        let fetchExpectation = expectation(description: "testFetch")
        let decodeExpectation = expectation(description: "testDecode")
        let fetchAndDecodeExpectation = expectation(description: "testFetchAndDecode")
        defer { waitForExpectations(timeout: 1) }

        stack.mockFetch = { resource, completion in
            fetchExpectation.fulfill()
            XCTAssertEqual(resource, self.resource)
            completion(.success(self.networkValue))
            return MockCancelable()
        }

        let decoding = NetworkDecoding<Double>.mock { payload, metadata in
            decodeExpectation.fulfill()
            XCTAssertEqual(payload, self.networkValue.value)
            XCTAssertEqual(metadata, self.networkValue.response)
            return .failure(MockDecodeError.💣)
        }

        stack.fetchAndDecode(resource: resource, decoding: decoding) { result in

            defer { fetchAndDecodeExpectation.fulfill() }

            switch result {
            case .failure(.decode(MockDecodeError.💣)):
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
        let fetchAndDecodeExpectation = expectation(description: "testFetchAndDecode")
        defer { waitForExpectations(timeout: 1) }

        let mockDecodedValue = 1.337

        stack.mockFetch = { resource, completion in
            fetchExpectation.fulfill()
            XCTAssertEqual(resource, self.resource)
            completion(.success(self.networkValue))
            return MockCancelable()
        }

        let decoding = NetworkDecoding<Double>.mock { payload, metadata in
            decodeExpectation.fulfill()
            XCTAssertEqual(payload, self.networkValue.value)
            XCTAssertEqual(metadata, self.networkValue.response)
            return .success(mockDecodedValue)
        }

        stack.fetchAndDecode(resource: resource, decoding: decoding) { result in

            defer { fetchAndDecodeExpectation.fulfill() }

            switch result {
            case .success(let value):
                XCTAssertEqual(value.value, mockDecodedValue)
                XCTAssertEqual(value.response, self.networkValue.response)
            default:
                return XCTFail("🔥 Unexpected result: \(result)!")
            }
        }
    }
}

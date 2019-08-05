import XCTest

@testable import Alicerce

final class URLSessionNetworkStack_ErrorTestCase: XCTestCase {

    typealias Error = Network.URLSessionNetworkStack.Error

    func testErrorResponse_WhenCaseContainsResponse_ShouldReturnIt() {

        enum DummyError: Swift.Error { case 🕳 }

        let testResponse = URLResponse(url: URL(string: "https://mindera.com")!,
                                       mimeType: nil,
                                       expectedContentLength: 1337,
                                       textEncodingName: nil)

        let httpError = Error.http(.unknownError(1337), DummyError.🕳, testResponse)
        let noDataError = Error.noData(testResponse)
        let urlError = Error.url(URLError(.badURL), testResponse)
        let badResponseError = Error.badResponse(testResponse)
        let retryError = Error.retry(.cancelled, [], 0, testResponse)

        XCTAssertEqual(httpError.response, testResponse)
        XCTAssertEqual(noDataError.response, testResponse)
        XCTAssertEqual(urlError.response, testResponse)
        XCTAssertEqual(badResponseError.response, testResponse)
        XCTAssertEqual(retryError.response, testResponse)
    }

    func testErrorResponse_WhenCaseDoesNotContainsResponse_ShouldReturnNil() {

        enum DummyError: Swift.Error { case 🕳 }

        let noRequestError = Error.noRequest(DummyError.🕳)
        let urlError = Error.url(URLError(.badURL), nil)
        let badResponseError = Error.badResponse(nil)
        let retryError = Error.retry(.cancelled, [], 0, nil)

        XCTAssertNil(noRequestError.response)
        XCTAssertNil(urlError.response)
        XCTAssertNil(badResponseError.response)
        XCTAssertNil(retryError.response)
    }

    func testLastError_ShouldReturnCorrectError() {

        enum DummyError: Swift.Error { case 🕳 }

        let testResponse = URLResponse(url: URL(string: "https://mindera.com")!,
                                       mimeType: nil,
                                       expectedContentLength: 1337,
                                       textEncodingName: nil)

        let noRequestError = Error.noRequest(DummyError.🕳)
        let httpError = Error.http(.unknownError(1337), DummyError.🕳, testResponse)
        let noDataError = Error.noData(testResponse)
        let urlError = Error.url(URLError(.badURL), testResponse)
        let badResponseError = Error.badResponse(testResponse)

        let retryError = Error.retry(.cancelled, [DummyError.🕳, urlError], 0, testResponse)
        let retryError2 = Error.retry(.cancelled, [DummyError.🕳, DummyError.🕳], 0, testResponse)

        XCTAssertDumpsEqual(noRequestError.lastError, noRequestError)
        XCTAssertDumpsEqual(httpError.lastError, httpError)
        XCTAssertDumpsEqual(noDataError.lastError, noDataError)
        XCTAssertDumpsEqual(urlError.lastError, urlError)
        XCTAssertDumpsEqual(badResponseError.lastError, badResponseError)

        XCTAssertDumpsEqual(retryError.lastError, urlError)
        XCTAssertDumpsEqual(retryError2.lastError, retryError2)
    }

    func testStatusCode_ShouldReturnCorrectStatusCode() {

        enum DummyError: Swift.Error { case 🕳 }

        let testResponse = URLResponse(url: URL(string: "https://mindera.com")!,
                                       mimeType: nil,
                                       expectedContentLength: 1337,
                                       textEncodingName: nil)

        let noRequestError = Error.noRequest(DummyError.🕳)
        let httpError = Error.http(.unknownError(1337), DummyError.🕳, testResponse)
        let noDataError = Error.noData(testResponse)
        let urlError = Error.url(URLError(.badURL), testResponse)
        let badResponseError = Error.badResponse(testResponse)

        let retryError = Error.retry(.cancelled, [DummyError.🕳, httpError], 0, testResponse)
        let retryError2 = Error.retry(.cancelled, [DummyError.🕳, DummyError.🕳], 0, testResponse)

        XCTAssertNil(noRequestError.statusCode)
        XCTAssertEqual(httpError.statusCode, .unknownError(1337))
        XCTAssertNil(noDataError.statusCode)
        XCTAssertNil(urlError.statusCode)
        XCTAssertNil(badResponseError.statusCode)

        XCTAssertEqual(retryError.statusCode, .unknownError(1337))
        XCTAssertNil(retryError2.statusCode)
    }
}

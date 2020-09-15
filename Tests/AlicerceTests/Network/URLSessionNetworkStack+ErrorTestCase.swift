import XCTest

@testable import Alicerce

final class URLSessionNetworkStack_ErrorTestCase: XCTestCase {

    typealias Error = Network.URLSessionError

    func testErrorResponse_ShouldReturnCorrectResponse() {

        enum DummyError: Swift.Error { case 🕳 }

        let testResponse = URLResponse(url: URL(string: "https://mindera.com")!,
                                       mimeType: nil,
                                       expectedContentLength: 1337,
                                       textEncodingName: nil)

        let noRequestError = Error.noRequest(DummyError.🕳)
        let httpError = Error.http(.unknownError(1337), DummyError.🕳, testResponse)
        let noDataError = Error.noData(testResponse)
        let urlError = Error.url(URLError(.badURL))
        let badResponseError = Error.badResponse(testResponse)
        let badNilResponseError = Error.badResponse(nil)
        let retryError = Error.retry(.retries(1337), .empty)
        let cancelledError = Error.cancelled

        XCTAssertNil(noRequestError.response)
        XCTAssertEqual(httpError.response, testResponse)
        XCTAssertEqual(noDataError.response, testResponse)
        XCTAssertNil(urlError.response)
        XCTAssertEqual(badResponseError.response, testResponse)
        XCTAssertNil(badNilResponseError.response)
        XCTAssertNil(retryError.response)
        XCTAssertNil(cancelledError.response)
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
        let urlError = Error.url(URLError(.badURL))
        let badResponseError = Error.badResponse(testResponse)
        let retryError = Error.retry(.retries(1337), .init(errors: [DummyError.🕳, urlError], totalDelay: 0))
        let retryError2 = Error.retry(.retries(1337), .init(errors: [DummyError.🕳, DummyError.🕳], totalDelay: 0))
        let cancelledError = Error.cancelled

        XCTAssertDumpsEqual(noRequestError.lastError, noRequestError)
        XCTAssertDumpsEqual(httpError.lastError, httpError)
        XCTAssertDumpsEqual(noDataError.lastError, noDataError)
        XCTAssertDumpsEqual(urlError.lastError, urlError)
        XCTAssertDumpsEqual(badResponseError.lastError, badResponseError)
        XCTAssertDumpsEqual(retryError.lastError, urlError)
        XCTAssertDumpsEqual(retryError2.lastError, retryError2)
        XCTAssertDumpsEqual(cancelledError.lastError, cancelledError)
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
        let urlError = Error.url(URLError(.badURL))
        let badResponseError = Error.badResponse(testResponse)
        let retryError = Error.retry(.retries(1337), .init(errors: [DummyError.🕳, httpError], totalDelay: 0))
        let retryError2 = Error.retry(.retries(1337), .init(errors: [DummyError.🕳, DummyError.🕳], totalDelay: 0))
        let cancelledError = Error.cancelled

        XCTAssertNil(noRequestError.statusCode)
        XCTAssertEqual(httpError.statusCode, .unknownError(1337))
        XCTAssertNil(noDataError.statusCode)
        XCTAssertNil(urlError.statusCode)
        XCTAssertNil(badResponseError.statusCode)
        XCTAssertEqual(retryError.statusCode, .unknownError(1337))
        XCTAssertNil(retryError2.statusCode)
        XCTAssertNil(cancelledError.statusCode)
    }
}

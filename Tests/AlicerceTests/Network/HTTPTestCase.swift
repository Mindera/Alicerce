// Copyright © 2018 Mindera. All rights reserved.

import XCTest
@testable import Alicerce

class HTTPTestCase: XCTestCase {

    // MARK: - StatusCode

    // init(statusCode:)

    func testStatusCodeInit_WithStatusCode_ShouldReturnCorrectValue() {

        XCTAssertEqual(HTTP.StatusCode(Int.min), .unknownError(Int.min))
        XCTAssertEqual(HTTP.StatusCode(99), .unknownError(99))

        XCTAssertEqual(HTTP.StatusCode(100), .informational(100))
        XCTAssertEqual(HTTP.StatusCode(199), .informational(199))

        XCTAssertEqual(HTTP.StatusCode(200), .success(200))
        XCTAssertEqual(HTTP.StatusCode(299), .success(299))

        XCTAssertEqual(HTTP.StatusCode(300), .redirection(300))
        XCTAssertEqual(HTTP.StatusCode(399), .redirection(399))

        XCTAssertEqual(HTTP.StatusCode(400), .clientError(400))
        XCTAssertEqual(HTTP.StatusCode(499), .clientError(499))

        XCTAssertEqual(HTTP.StatusCode(500), .serverError(500))
        XCTAssertEqual(HTTP.StatusCode(599), .serverError(599))

        XCTAssertEqual(HTTP.StatusCode(600), .unknownError(600))
        XCTAssertEqual(HTTP.StatusCode(Int.max), .unknownError(Int.max))
    }

    // statusCode

    func testStatusCodeGetStatusCode_ShouldReturnCorrectValue() {

        XCTAssertEqual(HTTP.StatusCode(Int.min).statusCode, Int.min)
        XCTAssertEqual(HTTP.StatusCode(99).statusCode, 99)

        XCTAssertEqual(HTTP.StatusCode(100).statusCode, 100)
        XCTAssertEqual(HTTP.StatusCode(199).statusCode, 199)

        XCTAssertEqual(HTTP.StatusCode(200).statusCode, 200)
        XCTAssertEqual(HTTP.StatusCode(299).statusCode, 299)

        XCTAssertEqual(HTTP.StatusCode(300).statusCode, 300)
        XCTAssertEqual(HTTP.StatusCode(399).statusCode, 399)

        XCTAssertEqual(HTTP.StatusCode(400).statusCode, 400)
        XCTAssertEqual(HTTP.StatusCode(499).statusCode, 499)

        XCTAssertEqual(HTTP.StatusCode(500).statusCode, 500)
        XCTAssertEqual(HTTP.StatusCode(599).statusCode, 599)

        XCTAssertEqual(HTTP.StatusCode(600).statusCode, 600)
        XCTAssertEqual(HTTP.StatusCode(Int.max).statusCode, Int.max)
    }
}

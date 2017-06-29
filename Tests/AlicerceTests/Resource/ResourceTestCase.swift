//
//  ResourceTestCase.swift
//  Alicerce
//
//  Created by Luís Portela on 11/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest

@testable import Alicerce

final class ResourceTestCase: XCTestCase {

    enum APIError: Error {
        case 💣
    }

    func testResource_WithFullInit_ItShouldPopulateAllValues() {

        let path = "/"
        let method = HTTP.Method.GET
        let headers: HTTP.Headers = ["👉" : "😝"]
        let query: HTTP.Query = ["👉" : "😜"]
        let body = "👀".data(using: .utf8)
        let parser: (Data) throws -> String = { _ in "" }
        let apiErrorParser: (Data) -> APIError? = { _ in .💣 }

        let resource = Resource<String, APIError>(path: path,
                                                  method: method,
                                                  headers: headers,
                                                  query: query,
                                                  body: body,
                                                  parser: parser,
                                                  apiErrorParser: apiErrorParser)

        XCTAssertEqual(resource.path, path)
        XCTAssertEqual(resource.method, method)
        XCTAssertEqual(resource.headers!, headers)
        XCTAssertEqual(resource.query!, query)
        XCTAssertEqual(resource.body, body)
    }

    func testResource_WithSimpleInit_ItShouldUseDefaultValues() {

        let path = "/"
        let method = HTTP.Method.GET
        let parser: (Data) throws -> String = { _ in "" }
        let apiErrorParser: (Data) -> APIError? = { _ in .💣 }

        let resource = Resource<String, APIError>(path: path,
                                                  method: method,
                                                  parser: parser,
                                                  apiErrorParser: apiErrorParser)

        XCTAssertEqual(resource.path, path)
        XCTAssertEqual(resource.method, method)

        // test default values
        XCTAssertNil(resource.headers)
        XCTAssertNil(resource.query)
        XCTAssertNil(resource.body)
    }
}

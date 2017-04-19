//
//  NetworkResourceTestCase.swift
//  Alicerce
//
//  Created by Luís Portela on 11/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest

@testable import Alicerce

final class NetworkResourceTestCase: XCTestCase {

    func testToRequest_WhenProvidedARequestWithAllValues_ItShouldReturnAValidURLRequest() {
        let path = "/"
        let method = HTTP.Method.GET
        let headers: HTTP.Headers = ["👉" : "😜"]
        let query: HTTP.Query = ["param1" : "value1"]
        let body = "👀".data(using: .utf8)
        let parser: (Data) throws -> String = { _ in "" }

        let resource = Resource<String>(path: path,
                                        method: method,
                                        headers: headers,
                                        query: query,
                                        body: body,
                                        parser: parser)

        let baseURL = URL(string: "http://localhost")!

        let urlRequest = resource.toRequest(withBaseURL: baseURL)

        XCTAssertEqual(urlRequest.url?.absoluteString, "http://localhost/?param1=value1")
        XCTAssertNotNil(urlRequest.httpMethod)
        XCTAssertEqual(urlRequest.httpMethod, method.rawValue)
        XCTAssertNotNil(urlRequest.allHTTPHeaderFields)
        XCTAssertEqual(urlRequest.allHTTPHeaderFields!, headers)
        XCTAssertNotNil(urlRequest.httpBody)
        XCTAssertEqual(urlRequest.httpBody, body)
    }
}

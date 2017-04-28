//
//  NetworkTestCase.swift
//  Alicerce
//
//  Created by Luís Portela on 11/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest

@testable import Alicerce

final class NetworkTestCase: XCTestCase {

    func testConfiguration_WhenCreateWithFullInit_ItShouldPopulateAllTheValues() {

        let url = URL(string: "http://localhost")!

        let networkConfiguration = Network.Configuration(baseURL: url)

        XCTAssertEqual(networkConfiguration.baseURL, url)
    }
}

private final class MockURLSessionConfiguration: URLSessionConfiguration {

    private var headers: [AnyHashable : Any]? = ["👉" : "👈"]

    override var httpAdditionalHeaders: [AnyHashable : Any]? {
        get {
            return headers
        }

        set {
            headers = newValue
        }
    }
}

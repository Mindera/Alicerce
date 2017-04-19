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

        let sessionConfiguration = MockURLSessionConfiguration()

        let delegateQueue: OperationQueue = {
            $0.name = "📱"
            return $0
        }(OperationQueue())


        let networkConfiguration = Network.Configuration(baseURL: url,
                                                         sessionConfiguration: sessionConfiguration,
                                                         delegateQueue: delegateQueue)

        XCTAssertEqual(networkConfiguration.baseURL, url)
        XCTAssertEqual(networkConfiguration.sessionConfiguration, networkConfiguration.sessionConfiguration)
        XCTAssertEqual(networkConfiguration.sessionConfiguration.httpAdditionalHeaders?["👉"] as! String, "👈")
        XCTAssertEqual(networkConfiguration.delegateQueue, delegateQueue)
        XCTAssertEqual(networkConfiguration.delegateQueue?.name, delegateQueue.name)
    }

    func testConfiguration_WhenCreateWithBaseURLInit_ItShouldPopulateTheBaseURLAndTheDefaultValues() {

        let url = URL(string: "http://localhost")!

        let networkConfiguration = Network.Configuration(baseURL: url)

        XCTAssertEqual(networkConfiguration.baseURL, url)
        XCTAssertEqual(networkConfiguration.sessionConfiguration, URLSessionConfiguration.default)
        XCTAssertNil(networkConfiguration.delegateQueue)
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

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
        XCTAssertNil(networkConfiguration.authenticationChallengeValidator)
        XCTAssertNil(networkConfiguration.authenticator)
        XCTAssertTrue(networkConfiguration.requestHandlers.isEmpty)
    }
    
    func testConfiguration_WhenCreatedWithARequestHandler_ItShouldKeepAReferenceToIt() {
        let url = URL(string: "http://localhost")!
        let dummyRequestHandler = DummyRequestHandler()
        
        let requestHandlers = [dummyRequestHandler]
        
        let networkConfiguration = Network.Configuration(baseURL: url, requestHandlers: requestHandlers)
        
        XCTAssertEqual(networkConfiguration.baseURL, url)
        XCTAssertNil(networkConfiguration.authenticationChallengeValidator)
        XCTAssertNil(networkConfiguration.authenticator)
        XCTAssertEqual(networkConfiguration.requestHandlers.count, 1)
        
        guard let configurationDummyRequestHandler = networkConfiguration.requestHandlers.first as? DummyRequestHandler
        else { return XCTFail("💥") }
        
        XCTAssertEqual(configurationDummyRequestHandler, dummyRequestHandler)
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

private final class DummyRequestHandler: RequestHandler {
    func handle(request: URLRequest) {}
    
    func request(_ request: URLRequest, handleResponse response: URLResponse?, error: Error?) {}
}

extension DummyRequestHandler: Equatable {
    static func ==(left: DummyRequestHandler, right: DummyRequestHandler) -> Bool {
        return true
    }
}

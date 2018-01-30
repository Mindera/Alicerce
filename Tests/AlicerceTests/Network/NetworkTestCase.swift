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

        let networkConfiguration = Network.Configuration()

        XCTAssertNil(networkConfiguration.authenticationChallengeValidator)
        XCTAssertNil(networkConfiguration.authenticator)
        XCTAssertTrue(networkConfiguration.requestInterceptors.isEmpty)
    }
    
    func testConfiguration_WhenCreatedWithARequestHandler_ItShouldKeepAReferenceToIt() {
        let dummyRequestInterceptor = DummyRequestInterceptor()
        
        let requestInterceptors = [dummyRequestInterceptor]
        
        let networkConfiguration = Network.Configuration(requestInterceptors: requestInterceptors)
        
        XCTAssertNil(networkConfiguration.authenticationChallengeValidator)
        XCTAssertNil(networkConfiguration.authenticator)
        XCTAssertEqual(networkConfiguration.requestInterceptors.count, 1)
        
        guard let configurationDummyRequestInterceptor
            = networkConfiguration.requestInterceptors.first as? DummyRequestInterceptor
        else { return XCTFail("💥") }
        
        XCTAssertEqual(configurationDummyRequestInterceptor, dummyRequestInterceptor)
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

private final class DummyRequestInterceptor: RequestInterceptor {
    func intercept(request: URLRequest) {}
    
    func intercept(response: URLResponse?, data: Data?, error: Error?, for request: URLRequest) {}
}

extension DummyRequestInterceptor: Equatable {
    static func ==(left: DummyRequestInterceptor, right: DummyRequestInterceptor) -> Bool {
        return true
    }
}

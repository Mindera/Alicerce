//
//  ConfigurationTestCase.swift
//  Alicerce
//
//  Created by Luís Portela on 27/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest

@testable import Alicerce

final class ConfigurationTestCase: XCTestCase {
    
    func testConfiguration_UsingDefaultInit_ItShouldCreateAnInstanceWithDefaultValues() {
        let configuration = Analytics.Configuration()
        
        XCTAssertEqual(configuration.queueQoS, DispatchQoS.default)
        XCTAssertNil(configuration.extraParameters)
    }
    
    func testConfiguration_WithADifferentDispatchQoS_ItShouldCreateAnInstanceWithDifferentValues() {
        let configuration = Analytics.Configuration(queueQoS: DispatchQoS.utility)
        
        XCTAssertEqual(configuration.queueQoS, DispatchQoS.utility)
        XCTAssertNil(configuration.extraParameters)
    }
    
    func testConfiguration_WithParameters_ItShouldPopulateWithParameters() {
        let configuration = Analytics.Configuration(extraParameters: ["1" : "1"])
        
        XCTAssertEqual(configuration.queueQoS, DispatchQoS.default)
        XCTAssertNotNil(configuration.extraParameters)
        XCTAssertEqual(configuration.extraParameters?.count, 1)
    }
    
    func testConfiguration_WithDispatchAndParameters_ItShouldBePopulatedWithThoseValues() {
        let configuration = Analytics.Configuration(queueQoS: DispatchQoS.utility, extraParameters: ["1" : "1"])
        
        XCTAssertEqual(configuration.queueQoS, DispatchQoS.utility)
        XCTAssertNotNil(configuration.extraParameters)
        XCTAssertEqual(configuration.extraParameters?.count, 1)
    }
}

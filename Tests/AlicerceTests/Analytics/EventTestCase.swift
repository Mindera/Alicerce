//
//  EventTestCase.swift
//  Alicerce
//
//  Created by Luís Portela on 27/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest

@testable import Alicerce

final class EventTestCase: XCTestCase {
    
    func testEvent_WithOnlyNameProvided_ItShouldPopulateOnlyTheName() {
        let event = Analytics.Event(name: "💣", parameters: nil)
        
        XCTAssertEqual(event.name, "💣")
        XCTAssertNil(event.parameters)
    }
    
    func testEvent_WithProvidedNameAndParameters_ItShouldPopulateOnlyTheName() {
        let event = Analytics.Event(name: "👯", parameters: ["1" : "1"])
        
        XCTAssertEqual(event.name, "👯")
        XCTAssertNotNil(event.parameters)
        XCTAssertEqual(event.parameters?.count, 1)
    }
    
    func testEvents_WithDifferentValuesProvided_ShouldBeDifferent(){
        let lhs = Analytics.Event(name: "👯", parameters: ["1" : "1"])
        let rhs = Analytics.Event(name: "💣", parameters: ["1" : "2"])
        
        XCTAssertNotEqual(lhs,rhs)
    }
    
    func testPages_WithSameValuesProvided_ShouldBeEqual(){
        let lhs = Analytics.Event(name: "👯", parameters: ["1" : "1"])
        let rhs = Analytics.Event(name: "👯", parameters: ["1" : "1"])
        
        XCTAssertEqual(lhs,rhs)
    }
}

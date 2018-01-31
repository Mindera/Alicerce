//
//  BoolTestCase.swift
//  AlicerceTests
//
//  Created by David Beleza on 25/01/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class BoolTestCase: XCTestCase {
    
    func testBoolToggle() {
        
        var boolValue = false
        
        boolValue.toggle()
        XCTAssertTrue(boolValue)
        
        boolValue.toggle()
        XCTAssertFalse(boolValue)
    }
}

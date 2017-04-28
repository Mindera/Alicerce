//
//  PageTestCase.swift
//  Alicerce
//
//  Created by Luís Portela on 27/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest

@testable import Alicerce

final class PageTestCase: XCTestCase {
    
    func testPage_WithOnlyNameProvided_ItShouldPopulateOnlyTheName() {
        let page = Analytics.Page(name: "🤠", parameters: nil)
        
        XCTAssertEqual(page.name, "🤠")
        XCTAssertNil(page.parameters)
    }
    
    func testPage_WithProvidedNameAndParameters_ItShouldPopulateOnlyTheName() {
        let page = Analytics.Page(name: "🔨", parameters: ["1" : "1"])
        
        XCTAssertEqual(page.name, "🔨")
        XCTAssertNotNil(page.parameters)
        XCTAssertEqual(page.parameters?.count, 1)
    }
}

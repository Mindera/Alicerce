//
//  MappableErrorTestCase.swift
//  Alicerce
//
//  Created by Luís Portela on 11/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest

@testable import Alicerce

final class MappableErrorTestCase: XCTestCase {

    func testDescription_WhenAvailable_ItShouldReturnAString() {
        let mappableError = MappableError.custom("👍")

        XCTAssertEqual(mappableError.description, "👍")
    }
}

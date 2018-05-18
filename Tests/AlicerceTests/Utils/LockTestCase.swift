//
//  LockTestCase.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 13/04/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class LockTestCase: XCTestCase {

    func testMake_WithiOS10OrAbove_ShouldReturnAnUnfairLock() {
        let lock = Lock.make()

        XCTAssert(lock is Lock.UnfairLock)
    }
}

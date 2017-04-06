//
//  XCTestCase.swift
//  Alicerce
//
//  Created by Meik Schutz on 06/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest

extension XCTestCase {
    func eventually(timeout: TimeInterval = 0.01, closure: @escaping () -> Void) {
        let expectation = self.expectation(description: "")
        expectation.fulfillAfter(timeout)
        self.waitForExpectations(timeout: 60) { _ in
            closure()
        }
    }
}

extension XCTestExpectation {
    func fulfillAfter(_ time: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + time) {
            self.fulfill()
        }
    }
}

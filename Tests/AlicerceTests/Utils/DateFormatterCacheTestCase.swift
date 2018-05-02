//
//  DateFormatterCacheTestCase.swift
//  Alicerce
//
//  Created by Filipe Lemos on 02/05/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

extension String: DateFormatterBuilder {
    public func dateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = self
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }
}

class DateFormatterCacheTestCase: XCTestCase {

    private var cache: DateFormatterCache!

    override func setUp() {
        super.setUp()

        cache = DateFormatterCache()
    }

    override func tearDown() {
        cache = nil

        super.tearDown()
    }

    func testCache_WithBuilder_ShouldReturnCorrectFormatter() {

        let dateFormatter = cache.dateFormatter("yyyy-MM-dd'T'HH:mm:ssZ")
        let date = Date(timeIntervalSince1970: TimeInterval(0.0))

        XCTAssertEqual(dateFormatter.string(from: date), "1970-01-01T00:00:00+0000")
    }

    func testCache_WithSameBuilder_ShouldReturnSameFormatter() {

        let dateFormatter = cache.dateFormatter("yyyy-MM-dd'T'HH:mm:ssZ")
        let dateFormatter2 = cache.dateFormatter("yyyy-MM-dd'T'HH:mm:ssZ")

        XCTAssertTrue(dateFormatter === dateFormatter2)
    }

    func testCache_WithDifferentBuilders_ShouldReturnDifferentFormatters() {

        let dateFormatter1 = cache.dateFormatter("yyyy-MM-dd'T'HH:mm:ssZ")
        let dateFormatter2 = cache.dateFormatter("yyyy-MM-dd'T'HH:mm:ssZ")

        XCTAssertTrue(dateFormatter1 === dateFormatter2)
    }

    func testDateFormatter_WithDifferentConfiguration_ShouldReturnDifferentbject() {

        let dateFormatter1 = cache.dateFormatter("yyyy-MM-dd'T'HH:mm:ssZ")
        let dateFormatter2 = cache.dateFormatter("yyyy-MM-dd'T'HH:mm:ss")

        XCTAssertFalse(dateFormatter1 === dateFormatter2)
    }
}

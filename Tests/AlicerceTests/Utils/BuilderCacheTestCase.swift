//
//  BuilderCacheTestCase.swift
//  Alicerce
//
//  Created by Filipe Lemos on 02/05/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class BuilderCacheTestCase: XCTestCase {

    private struct SimpleDateFormatterKey: BuilderKey {

        private let dateFormat: String

        init(_ dateFormat: String) {
            self.dateFormat = dateFormat
        }

        func build() -> DateFormatter {
            let formatter = DateFormatter()
            formatter.dateFormat = dateFormat
            formatter.timeZone = TimeZone(identifier: "UTC")
            return formatter
        }
    }

    private enum ComplexDateFormatterKey: BuilderKey {
        case local(dateFormat: String)
        case utc(dateFormat: String)

        func build() -> DateFormatter {
            let formatter = DateFormatter()
            switch self {
                case .utc: formatter.timeZone = TimeZone(identifier: "UTC")
                case .local: break // local device timezone
            }
            switch self {
            case .local(let dateFormat),
                 .utc(let dateFormat):
                formatter.dateFormat = dateFormat
            }
            return formatter
        }
    }

    // MARK: - Setup

    private var cache: BuilderCache<DateFormatter>!

    override func setUp() {
        super.setUp()

        cache = BuilderCache()
    }

    override func tearDown() {

        cache = nil

        super.tearDown()
    }

    // MARK: - Tests

    func testCache_WithSimpleKey_ShouldReturnCorrectObject() {

        let dateFormatter = cache.object(SimpleDateFormatterKey("yyyy-MM-dd'T'HH:mm:ssZ"))
        let date = Date(timeIntervalSince1970: TimeInterval(0.0))

        XCTAssertEqual(dateFormatter.string(from: date), "1970-01-01T00:00:00+0000")
    }

    func testCache_WithComplexKey_ShouldReturnCorrectObject() {

        let dateFormatter = cache.object(ComplexDateFormatterKey.utc(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZ"))
        let date = Date(timeIntervalSince1970: TimeInterval(0.0))

        XCTAssertEqual(dateFormatter.string(from: date), "1970-01-01T00:00:00+0000")
    }

    func testCache_WithSameSimpleKey_ShouldReturnSameObject() {

        let dateFormatter1 = cache.object(SimpleDateFormatterKey("yyyy-MM-dd'T'HH:mm:ssZ"))
        let dateFormatter2 = cache.object(SimpleDateFormatterKey("yyyy-MM-dd'T'HH:mm:ssZ"))

        XCTAssertTrue(dateFormatter1 === dateFormatter2)
    }

    func testCache_WithSameComplexKey_ShouldReturnSameObject() {

        let dateFormatter1 = cache.object(ComplexDateFormatterKey.utc(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZ"))
        let dateFormatter2 = cache.object(ComplexDateFormatterKey.utc(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZ"))

        XCTAssertTrue(dateFormatter1 === dateFormatter2)
    }

    func testCache_WithDifferentSimpleKeys_ShouldReturnDifferentObjects() {

        let dateFormatter1 = cache.object(SimpleDateFormatterKey("yyyy-MM-dd'T'HH:mm:ssZ"))
        let dateFormatter2 = cache.object(SimpleDateFormatterKey("yyyy-MM-dd'T'HH:mm:ss"))

        XCTAssertFalse(dateFormatter1 === dateFormatter2)
    }

    func testCache_WithDifferentComplexKey_ShouldReturnDifferentObjects() {

        let dateFormatter1 = cache.object(ComplexDateFormatterKey.utc(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZ"))
        let dateFormatter2 = cache.object(ComplexDateFormatterKey.local(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZ"))

        XCTAssertFalse(dateFormatter1 === dateFormatter2)
    }

    func testCache_WithDifferentKeyTypes_ShouldReturnDifferentObjects() {

        let dateFormatter1 = cache.object(SimpleDateFormatterKey("yyyy-MM-dd'T'HH:mm:ssZ"))
        let dateFormatter2 = cache.object(ComplexDateFormatterKey.utc(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZ"))

        XCTAssertFalse(dateFormatter1 === dateFormatter2)
    }

    func testCache_WithEvict_ShouldGenerateNewObject() {

        let dateFormatter1 = cache.object(SimpleDateFormatterKey("yyyy-MM-dd'T'HH:mm:ssZ"))
        cache.evict(SimpleDateFormatterKey("yyyy-MM-dd'T'HH:mm:ssZ"))
        let dateFormatter2 = cache.object(SimpleDateFormatterKey("yyyy-MM-dd'T'HH:mm:ssZ"))

        XCTAssertFalse(dateFormatter1 === dateFormatter2)
    }


    func testCache_WithEvictAll_ShouldGenerateNewObject() {

        let dateFormatter1 = cache.object(SimpleDateFormatterKey("yyyy-MM-dd'T'HH:mm:ssZ"))
        cache.evictAll()
        let dateFormatter2 = cache.object(SimpleDateFormatterKey("yyyy-MM-dd'T'HH:mm:ssZ"))

        XCTAssertFalse(dateFormatter1 === dateFormatter2)
    }
}

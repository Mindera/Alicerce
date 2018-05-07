//
//  GeneratableObjectCacheTestCase.swift
//  Alicerce
//
//  Created by Filipe Lemos on 02/05/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

extension String: GeneratableObjectKey {

    public func generate() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = self
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }
}

class GeneratableObjectCacheTestCase: XCTestCase {

    private struct SimpleDateFormatterKey: GeneratableObjectKey {

        private let dateFormat: String

        init(_ dateFormat: String) {
            self.dateFormat = dateFormat
        }

        func generate() -> DateFormatter {
            let formatter = DateFormatter()
            formatter.dateFormat = dateFormat
            formatter.timeZone = TimeZone(identifier: "UTC")
            return formatter
        }
    }

    private enum ComplexDateFormatterKey: GeneratableObjectKey {
        case local(dateFormat: String)
        case utc(dateFormat: String)

        func generate() -> DateFormatter {
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

    private var cache: GeneratableObjectCache<DateFormatter>!

    override func setUp() {
        super.setUp()

        cache = GeneratableObjectCache()
    }

    override func tearDown() {

        cache = nil

        super.tearDown()
    }

    // MARK: - Tests

    func testCache_WithStringKey_ShouldReturnCorrectObject() {

        let dateFormatter = cache.value("yyyy-MM-dd'T'HH:mm:ssZ")
        let date = Date(timeIntervalSince1970: TimeInterval(0.0))

        XCTAssertEqual(dateFormatter.string(from: date), "1970-01-01T00:00:00+0000")
    }

    func testCache_WithSimpleKey_ShouldReturnCorrectObject() {

        let dateFormatter = cache.value(SimpleDateFormatterKey("yyyy-MM-dd'T'HH:mm:ssZ"))
        let date = Date(timeIntervalSince1970: TimeInterval(0.0))

        XCTAssertEqual(dateFormatter.string(from: date), "1970-01-01T00:00:00+0000")
    }

    func testCache_WithComplexKey_ShouldReturnCorrectObject() {

        let dateFormatter = cache.value(ComplexDateFormatterKey.utc(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZ"))
        let date = Date(timeIntervalSince1970: TimeInterval(0.0))

        XCTAssertEqual(dateFormatter.string(from: date), "1970-01-01T00:00:00+0000")
    }

    func testCache_WithSameStringKey_ShouldReturnSameObject() {

        let dateFormatter1 = cache.value("yyyy-MM-dd'T'HH:mm:ssZ")
        let dateFormatter2 = cache.value("yyyy-MM-dd'T'HH:mm:ssZ")

        XCTAssertTrue(dateFormatter1 === dateFormatter2)
    }

    func testCache_WithSameSimpleKey_ShouldReturnSameObject() {

        let dateFormatter1 = cache.value(SimpleDateFormatterKey("yyyy-MM-dd'T'HH:mm:ssZ"))
        let dateFormatter2 = cache.value(SimpleDateFormatterKey("yyyy-MM-dd'T'HH:mm:ssZ"))

        XCTAssertTrue(dateFormatter1 === dateFormatter2)
    }

    func testCache_WithSameComplexKey_ShouldReturnSameObject() {

        let dateFormatter1 = cache.value(ComplexDateFormatterKey.utc(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZ"))
        let dateFormatter2 = cache.value(ComplexDateFormatterKey.utc(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZ"))

        XCTAssertTrue(dateFormatter1 === dateFormatter2)
    }

    func testCache_WithDifferentKeys_ShouldReturnDifferentObjects() {

        let dateFormatter1 = cache.value("yyyy-MM-dd'T'HH:mm:ssZ")
        let dateFormatter2 = cache.value("yyyy-MM-dd'T'HH:mm:ss")

        XCTAssertFalse(dateFormatter1 === dateFormatter2)
    }

    func testCache_WithDifferentKeyTypes_ShouldReturnDifferentObjects() {

        let dateFormatter1 = cache.value("yyyy-MM-dd'T'HH:mm:ssZ")
        let dateFormatter2 = cache.value(SimpleDateFormatterKey("yyyy-MM-dd'T'HH:mm:ssZ"))

        XCTAssertFalse(dateFormatter1 === dateFormatter2)
    }

    func testCache_WithDifferentComplexKey_ShouldReturnDifferentObjects() {

        let dateFormatter1 = cache.value(ComplexDateFormatterKey.utc(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZ"))
        let dateFormatter2 = cache.value(ComplexDateFormatterKey.local(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZ"))

        XCTAssertFalse(dateFormatter1 === dateFormatter2)
    }
}

//
//  JSONTests.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 20/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class JSONTests: XCTestCase {

    enum TestTypeA: String {
        case valueA
    }

    enum TestTypeB: Int {
        case valueB = 1337
    }

    let testKeyA: JSON.AttributeKey = "keyA"
    let testKeyB: JSON.AttributeKey = "keyB"

    let testValueA = "valueA"
    let testValueB = 1337

    lazy var testJSONDict: JSON.Dictionary = {
        return [self.testKeyA : self.testValueA,
                self.testKeyB : self.testValueB]
    }()

    lazy var testJSONDictData: Data = {
        return try! JSONSerialization.data(withJSONObject: self.testJSONDict,
                                           options: JSONSerialization.WritingOptions(rawValue: 0))
    }()

    lazy var testJSONArray: JSON.Array = {
        return [self.testKeyA,
                self.testKeyB]
    }()

    lazy var testJSONArrayData: Data = {
        return try! JSONSerialization.data(withJSONObject: self.testJSONArray,
                                           options: JSONSerialization.WritingOptions(rawValue: 0))
    }()

    // MARK: - parseDictionary

    func testParseDictionary_WithValidJSONDictionaryData_ShouldSucceed() {

        do {
            let jsonDict = try JSON.parseDictionary(from: testJSONDictData)

            assertEqualJSONDictionaries(jsonDict, testJSONDict)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseDictionary_WithInvalidJSONData_ShouldFailWithSerializationError() {

        let invalidJSONData = "💥".data(using: .utf8)!

        do {
            let _ = try JSON.parseDictionary(from: invalidJSONData)
            XCTFail("🔥: unexpected success!")
        } catch JSON.Error.serialization {
            // expected error 🎉
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseDictionary_WithUnexpectedJSONType_ShouldFailWithUnexpectedTypeError() {

        do {
            let _ = try JSON.parseDictionary(from: testJSONArrayData)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedType(expected, _) {
            // expected error 🎉
            XCTAssert(expected == JSON.Dictionary.self)
            // still not sending in `Array`, and also doesn't match `NSArray` (it returns an `__NSArrayI`), so... 🤷‍♂️
            // XCTAssert(found == type(of: testJSONArray))
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // MARK: - parseArray

    func testParseArray_WithValidJSONArrayData_ShouldSucceed() {

        do {
            let jsonArray = try JSON.parseArray(from: testJSONArrayData)

            XCTAssertEqual(jsonArray.count, testJSONArray.count)

            for (element, testElement) in zip(jsonArray, testJSONArray) {
                switch (element, testElement) {
                case let (e as Int, t as Int): XCTAssertEqual(e, t)
                case let (e as String, t as String): XCTAssertEqual(e, t)
                default: return XCTFail("🔥: unexpected types!")
                }
            }
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseArray_WithInvalidJSONData_ShouldFailWithSerializationError() {

        let invalidJSONData = "💥".data(using: .utf8)!

        do {
            let _ = try JSON.parseArray(from: invalidJSONData)
            XCTFail("🔥: unexpected success!")
        } catch JSON.Error.serialization {
            // expected error 🎉
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseArray_WithUnexpectedJSONType_ShouldFailWithUnexpectedTypeError() {

        do {
            let _ = try JSON.parseArray(from: testJSONDictData)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedType(expected, _) {
            // expected error 🎉
            XCTAssert(expected == JSON.Array.self)
            // still not sending in `Dictionary`, and also doesn't match `NSDictionary` (it returns an `__NSDictionaryI`), so... 🤷‍♂️
            // XCTAssert(found == type(of: testJSONDict))
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // MARK: - parseAttribute (specified type)

    func testParseAttribute_WithExistingAndExpectedType_ShouldSucceed() {

        do {
            let json = try JSON.parseDictionary(from: testJSONDictData)

            let valueA = try JSON.parseAttribute(String.self, key: testKeyA, json: json)
            let valueB = try JSON.parseAttribute(Int.self, key: testKeyB, json: json)

            XCTAssertEqual(valueA, testValueA)
            XCTAssertEqual(valueB, testValueB)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }


    func testParseAttribute_WithExistingAndExpectedAndValidType_ShouldSucceed() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            var didValidateA = false
            var didValidateB = false

            let startsWithValue: JSON.ParsePredicateClosure<String> = {
                didValidateA = true
                return $0.contains("value")
            }

            let isOdd: JSON.ParsePredicateClosure<Int> = {
                didValidateB = true
                return $0 % 2 == 1
            }

            let valueA = try JSON.parseAttribute(String.self, key: testKeyA, json: json, where: startsWithValue)
            let valueB = try JSON.parseAttribute(Int.self, key: testKeyB, json: json, where: isOdd)

            XCTAssertEqual(valueA, testValueA)
            XCTAssertEqual(valueB, testValueB)

            XCTAssert(didValidateA)
            XCTAssert(didValidateB)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseAttribute_WithNonExistentAttributeKey_ShouldFailWithMissingAttribute() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            let _ = try JSON.parseAttribute(String.self, key: nonExistentKey, json: json)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.missingAttribute(key, json: errorJSON) {
            // expected error 🎉
            assertEqualJSONDictionaries(json, errorJSON)
            XCTAssertEqual(key, nonExistentKey)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseAttribute_WithUnexpectedAttributeType_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            let _ = try JSON.parseAttribute(Double.self, key: testKeyA, json: json)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeType(key, expected, _, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            XCTAssert(expected == Double.self)

            // still not sending in `String`, and the returned `NSTaggedPointerString` is private API, so... 🤷‍♂️
            // XCTAssert(found == String.self)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseAttribute_WithUnexpectedAttributeValue_ShouldFailWithUnexpectedAttributeValue() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        var didValidate = false

        let isEmpty: JSON.ParsePredicateClosure<String> = {
            didValidate = true
            return $0.isEmpty
        }

        do {
            let _ = try JSON.parseAttribute(String.self, key: testKeyA, json: json, where: isEmpty)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeValue(key, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            assertEqualJSONDictionaries(json, errorJSON)
            XCTAssert(didValidate)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // non nil returning parseAPIError

    func testParseAttribute_WithNonExistentAttributeKeyAndParseAPIClosureReturningError_ShouldFailWithError() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        enum APIError: Swift.Error { case 💥 }
        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in APIError.💥 }

        do {
            let _ = try JSON.parseAttribute(String.self, key: nonExistentKey, json: json, parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch APIError.💥 {
            // expected error 🎉
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseAttribute_WithUnexpectedAttributeTypeAndParseAPIClosureReturningError_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        enum APIError: Swift.Error { case 💩 }
        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in APIError.💩 }

        do {
            let _ = try JSON.parseAttribute(Double.self, key: testKeyA, json: json, parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch APIError.💩 {
            // expected error 🎉
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // nil returning parseAPIError

    func testParseAttribute_WithNonExistentAttributeKeyAndParseAPIClosureReturningNil_ShouldFailWithMissingAttribute() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in nil }

        do {
            let _ = try JSON.parseAttribute(String.self, key: nonExistentKey, json: json, parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.missingAttribute(key, json: errorJSON) {
            // expected error 🎉
            assertEqualJSONDictionaries(json, errorJSON)
            XCTAssertEqual(key, nonExistentKey)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseAttribute_WithUnexpectedAttributeTypeAndParseAPIClosureReturningNil_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in nil }

        do {
            let _ = try JSON.parseAttribute(Double.self, key: testKeyA, json: json, parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeType(key, expected, _, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            XCTAssert(expected == Double.self)

            // still not sending in `String`, and the returned `NSTaggedPointerString` is private API, so... 🤷‍♂️
            // XCTAssert(found == String.self)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // MARK: - parseOptionalAttribute (specified type)

    func testParseOptionalAttribute_WithExistingAndExpectedType_ShouldSucceed() {

        do {
            let json = try JSON.parseDictionary(from: testJSONDictData)

            let valueA = try JSON.parseOptionalAttribute(String.self, key: testKeyA, json: json)
            let valueB = try JSON.parseOptionalAttribute(Int.self, key: testKeyB, json: json)

            XCTAssertEqual(valueA, testValueA)
            XCTAssertEqual(valueB, testValueB)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }


    func testParseOptionalAttribute_WithExistingAndExpectedAndValidType_ShouldSucceed() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            var didValidateA = false
            var didValidateB = false

            let startsWithValue: JSON.ParsePredicateClosure<String> = {
                didValidateA = true
                return $0.contains("value")
            }

            let isOdd: JSON.ParsePredicateClosure<Int> = {
                didValidateB = true
                return $0 % 2 == 1
            }

            let valueA = try JSON.parseOptionalAttribute(String.self, key: testKeyA, json: json, where: startsWithValue)
            let valueB = try JSON.parseOptionalAttribute(Int.self, key: testKeyB, json: json, where: isOdd)

            XCTAssertEqual(valueA, testValueA)
            XCTAssertEqual(valueB, testValueB)

            XCTAssert(didValidateA)
            XCTAssert(didValidateB)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalAttribute_WithNonExistentAttributeKey_ShouldSucceed() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            let nonExistent = try JSON.parseOptionalAttribute(String.self, key: nonExistentKey, json: json)

            XCTAssertNil(nonExistent)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalAttribute_WithUnexpectedAttributeType_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            let _ = try JSON.parseOptionalAttribute(Double.self, key: testKeyA, json: json)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeType(key, expected, _, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            XCTAssert(expected == Double.self)

            // still not sending in `String`, and the returned `NSTaggedPointerString` is private API, so... 🤷‍♂️
            // XCTAssert(found == String.self)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalAttribute_WithUnexpectedAttributeValue_ShouldFailWithUnexpectedAttributeValue() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        var didValidate = false

        let isEmpty: JSON.ParsePredicateClosure<String> = {
            didValidate = true
            return $0.isEmpty
        }

        do {
            let _ = try JSON.parseOptionalAttribute(String.self, key: testKeyA, json: json, where: isEmpty)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeValue(key, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            assertEqualJSONDictionaries(json, errorJSON)
            XCTAssert(didValidate)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // non nil returning parseAPIError

    func testParseOptionalAttribute_WithNonExistentAttributeKeyAndParseAPIClosureReturningError_ShouldFailWithError() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        enum APIError: Swift.Error { case 💥 }
        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in APIError.💥 }

        do {
            let _ = try JSON.parseOptionalAttribute(String.self,
                                                    key: nonExistentKey,
                                                    json: json,
                                                    parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch APIError.💥 {
            // expected error 🎉
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalAttribute_WithUnexpectedAttributeTypeAndParseAPIClosureReturningError_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        enum APIError: Swift.Error { case 💩 }
        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in APIError.💩 }

        do {
            let _ = try JSON.parseOptionalAttribute(Double.self,
                                                    key: testKeyA,
                                                    json: json,
                                                    parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch APIError.💩 {
            // expected error 🎉
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // nil returning parseAPIError

    func testParseOptionalAttribute_WithNonExistentAttributeKeyAndParseAPIClosureReturningNil_ShouldSucceed() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in nil }

        do {
            let nonExistent = try JSON.parseOptionalAttribute(String.self,
                                                              key: nonExistentKey,
                                                              json: json,
                                                              parseAPIError: parseAPIError)
            XCTAssertNil(nonExistent)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalAttribute_WithUnexpectedAttributeTypeAndParseAPIClosureReturningNil_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in nil }

        do {
            let _ = try JSON.parseOptionalAttribute(Double.self,
                                                    key: testKeyA,
                                                    json: json,
                                                    parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeType(key, expected, _, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            XCTAssert(expected == Double.self)

            // still not sending in `String`, and the returned `NSTaggedPointerString` is private API, so... 🤷‍♂️
            // XCTAssert(found == String.self)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // MARK: - parseRawRepresentableAttribute (specified type)

    func testParseRawRepresentableAttribute_WithExistingAndExpectedType_ShouldSucceed() {

        do {
            let json = try JSON.parseDictionary(from: testJSONDictData)

            let valueA = try JSON.parseRawRepresentableAttribute(TestTypeA.self, key: testKeyA, json: json)
            let valueB = try JSON.parseRawRepresentableAttribute(TestTypeB.self, key: testKeyB, json: json)

            XCTAssertEqual(valueA, .valueA)
            XCTAssertEqual(valueB, .valueB)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseRawRepresentableAttribute_WithNonExistentAttributeKey_ShouldFailWithMissingAttribute() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            let _ = try JSON.parseRawRepresentableAttribute(TestTypeA.self, key: nonExistentKey, json: json)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.missingAttribute(key, json: errorJSON) {
            // expected error 🎉
            assertEqualJSONDictionaries(json, errorJSON)
            XCTAssertEqual(key, nonExistentKey)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseRawRepresentableAttribute_WithUnexpectedAttributeType_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            let _ = try JSON.parseRawRepresentableAttribute(TestTypeB.self, key: testKeyA, json: json)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeType(key, expected, _, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            XCTAssert(expected == Int.self)

            // still not sending in `String`, and the returned `NSTaggedPointerString` is private API, so... 🤷‍♂️
            // XCTAssert(found == String.self)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseRawRepresentableAttribute_WithUnexpectedAttributeValue_ShouldFailWithUnexpectedAttributeValue() {

        var json = try! JSON.parseDictionary(from: testJSONDictData)
        json[testKeyA] = "invalid"

        do {
            let _ = try JSON.parseRawRepresentableAttribute(TestTypeA.self, key: testKeyA, json: json)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeValue(key, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // non nil returning parseAPIError

    func testParseRawRepresentableAttribute_WithNonExistentAttributeKeyAndParseAPIClosureReturningError_ShouldFailWithError() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        enum APIError: Swift.Error { case 💥 }
        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in APIError.💥 }

        do {
            let _ = try JSON.parseRawRepresentableAttribute(TestTypeA.self,
                                                            key: nonExistentKey,
                                                            json: json,
                                                            parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch APIError.💥 {
            // expected error 🎉
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseRawRepresentableAttribute_WithUnexpectedAttributeTypeAndParseAPIClosureReturningError_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        enum APIError: Swift.Error { case 💩 }
        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in APIError.💩 }

        do {
            let _ = try JSON.parseRawRepresentableAttribute(TestTypeB.self,
                                                            key: testKeyA,
                                                            json: json,
                                                            parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch APIError.💩 {
            // expected error 🎉
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // nil returning parseAPIError

    func testParseRawRepresentableAttribute_WithNonExistentAttributeKeyAndParseAPIClosureReturningNil_ShouldFailWithMissingAttribute() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in nil }

        do {
            let _ = try JSON.parseRawRepresentableAttribute(TestTypeA.self,
                                                            key: nonExistentKey,
                                                            json: json,
                                                            parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.missingAttribute(key, json: errorJSON) {
            // expected error 🎉
            assertEqualJSONDictionaries(json, errorJSON)
            XCTAssertEqual(key, nonExistentKey)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseRawRepresentableAttribute_WithUnexpectedAttributeTypeAndParseAPIClosureReturningNil_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in nil }

        do {
            let _ = try JSON.parseRawRepresentableAttribute(TestTypeB.self,
                                                            key: testKeyA,
                                                            json: json,
                                                            parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeType(key, expected, _, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            XCTAssert(expected == Int.self)

            // still not sending in `String`, and the returned `NSTaggedPointerString` is private API, so... 🤷‍♂️
            // XCTAssert(found == String.self)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // MARK: - parseOptionalRawRepresentableAttribute (specified type)

    func testParseOptionalRawRepresentableAttribute_WithExistingAndExpectedType_ShouldSucceed() {

        do {
            let json = try JSON.parseDictionary(from: testJSONDictData)

            let valueA = try JSON.parseOptionalRawRepresentableAttribute(TestTypeA.self, key: testKeyA, json: json)
            let valueB = try JSON.parseOptionalRawRepresentableAttribute(TestTypeB.self, key: testKeyB, json: json)

            XCTAssertEqual(valueA, .valueA)
            XCTAssertEqual(valueB, .valueB)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalRawRepresentableAttribute_WithNonExistentAttributeKey_ShouldSucceed() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            let nonExistent = try JSON.parseOptionalRawRepresentableAttribute(TestTypeA.self,
                                                                              key: nonExistentKey,
                                                                              json: json)

            XCTAssertNil(nonExistent)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalRawRepresentableAttribute_WithUnexpectedAttributeType_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            let _ = try JSON.parseOptionalRawRepresentableAttribute(TestTypeB.self, key: testKeyA, json: json)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeType(key, expected, _, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            XCTAssert(expected == Int.self)

            // still not sending in `String`, and the returned `NSTaggedPointerString` is private API, so... 🤷‍♂️
            // XCTAssert(found == String.self)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalRawRepresentableAttribute_WithUnexpectedAttributeValue_ShouldFailWithUnexpectedAttributeValue() {

        var json = try! JSON.parseDictionary(from: testJSONDictData)
        json[testKeyA] = "invalid"

        do {
            let _ = try JSON.parseOptionalRawRepresentableAttribute(TestTypeA.self, key: testKeyA, json: json)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeValue(key, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // non nil returning parseAPIError

    func testParseOptionalRawRepresentableAttribute_WithNonExistentAttributeKeyAndParseAPIClosureReturningError_ShouldFailWithError() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        enum APIError: Swift.Error { case 💥 }
        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in APIError.💥 }

        do {
            let _ = try JSON.parseOptionalRawRepresentableAttribute(TestTypeA.self,
                                                                    key: nonExistentKey,
                                                                    json: json,
                                                                    parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch APIError.💥 {
            // expected error 🎉
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalRawRepresentableAttribute_WithUnexpectedAttributeTypeAndParseAPIClosureReturningError_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        enum APIError: Swift.Error { case 💩 }
        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in APIError.💩 }

        do {
            let _ = try JSON.parseOptionalRawRepresentableAttribute(TestTypeB.self,
                                                                    key: testKeyA,
                                                                    json: json,
                                                                    parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch APIError.💩 {
            // expected error 🎉
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // nil returning parseAPIError

    func testParseOptionalRawRepresentableAttribute_WithNonExistentAttributeKeyAndParseAPIClosureReturningNil_ShouldSucceed() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in nil }

        do {
            let nonExistent = try JSON.parseOptionalRawRepresentableAttribute(TestTypeA.self,
                                                                              key: nonExistentKey,
                                                                              json: json,
                                                                              parseAPIError: parseAPIError)
            XCTAssertNil(nonExistent)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalRawRepresentableAttribute_WithUnexpectedAttributeTypeAndParseAPIClosureReturningNil_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in nil }

        do {
            let _ = try JSON.parseOptionalRawRepresentableAttribute(TestTypeB.self,
                                                                    key: testKeyA,
                                                                    json: json,
                                                                    parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeType(key, expected, _, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            XCTAssert(expected == Int.self)

            // still not sending in `String`, and the returned `NSTaggedPointerString` is private API, so... 🤷‍♂️
            // XCTAssert(found == String.self)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // MARK: - parseAttribute (inferred type)

    func testParseAttributeInferred_WithExistingAndExpectedType_ShouldSucceed() {

        do {
            let json = try JSON.parseDictionary(from: testJSONDictData)

            let valueA: String = try JSON.parseAttribute(testKeyA, json: json)
            let valueB: Int = try JSON.parseAttribute(testKeyB, json: json)

            XCTAssertEqual(valueA, testValueA)
            XCTAssertEqual(valueB, testValueB)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }


    func testParseAttributeInferred_WithExistingAndExpectedAndValidType_ShouldSucceed() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            var didValidateA = false
            var didValidateB = false

            let startsWithValue: JSON.ParsePredicateClosure<String> = {
                didValidateA = true
                return $0.contains("value")
            }

            let isOdd: JSON.ParsePredicateClosure<Int> = {
                didValidateB = true
                return $0 % 2 == 1
            }

            let valueA: String = try JSON.parseAttribute(testKeyA, json: json, where: startsWithValue)
            let valueB: Int = try JSON.parseAttribute(testKeyB, json: json, where: isOdd)

            XCTAssertEqual(valueA, testValueA)
            XCTAssertEqual(valueB, testValueB)

            XCTAssert(didValidateA)
            XCTAssert(didValidateB)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseAttributeInferred_WithNonExistentAttributeKey_ShouldFailWithMissingAttribute() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            let _: String = try JSON.parseAttribute(nonExistentKey, json: json)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.missingAttribute(key, json: errorJSON) {
            // expected error 🎉
            assertEqualJSONDictionaries(json, errorJSON)
            XCTAssertEqual(key, nonExistentKey)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseAttributeInferred_WithUnexpectedAttributeType_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            let _: Double = try JSON.parseAttribute(testKeyA, json: json)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeType(key, expected, _, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            XCTAssert(expected == Double.self)

            // still not sending in `String`, and the returned `NSTaggedPointerString` is private API, so... 🤷‍♂️
            // XCTAssert(found == String.self)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseAttributeInferred_WithUnexpectedAttributeValue_ShouldFailWithUnexpectedAttributeValue() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        var didValidate = false

        let isEmpty: JSON.ParsePredicateClosure<String> = {
            didValidate = true
            return $0.isEmpty
        }

        do {
            let _: String = try JSON.parseAttribute(testKeyA, json: json, where: isEmpty)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeValue(key, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            assertEqualJSONDictionaries(json, errorJSON)
            XCTAssert(didValidate)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // non nil returning parseAPIError

    func testParseAttributeInferred_WithNonExistentAttributeKeyAndParseAPIClosureReturningError_ShouldFailWithError() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        enum APIError: Swift.Error { case 💥 }
        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in APIError.💥 }

        do {
            let _: String = try JSON.parseAttribute(nonExistentKey, json: json, parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch APIError.💥 {
            // expected error 🎉
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseAttributeInferred_WithUnexpectedAttributeTypeAndParseAPIClosureReturningError_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        enum APIError: Swift.Error { case 💩 }
        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in APIError.💩 }

        do {
            let _: Double = try JSON.parseAttribute(testKeyA, json: json, parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch APIError.💩 {
            // expected error 🎉
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // nil returning parseAPIError

    func testParseAttributeInferred_WithNonExistentAttributeKeyAndParseAPIClosureReturningNil_ShouldFailWithMissingAttribute() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in nil }

        do {
            let _: String = try JSON.parseAttribute(nonExistentKey, json: json, parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.missingAttribute(key, json: errorJSON) {
            // expected error 🎉
            assertEqualJSONDictionaries(json, errorJSON)
            XCTAssertEqual(key, nonExistentKey)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseAttributeInferred_WithUnexpectedAttributeTypeAndParseAPIClosureReturningNil_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in nil }

        do {
            let _: Double = try JSON.parseAttribute(testKeyA, json: json, parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeType(key, expected, _, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            XCTAssert(expected == Double.self)

            // still not sending in `String`, and the returned `NSTaggedPointerString` is private API, so... 🤷‍♂️
            // XCTAssert(found == String.self)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // MARK: - parseOptionalAttribute (inferred type)

    func testParseOptionalAttributeInferred_WithExistingAndExpectedType_ShouldSucceed() {

        do {
            let json = try JSON.parseDictionary(from: testJSONDictData)

            let valueA: String? = try JSON.parseOptionalAttribute(testKeyA, json: json)
            let valueB: Int? = try JSON.parseOptionalAttribute(testKeyB, json: json)

            XCTAssertEqual(valueA, testValueA)
            XCTAssertEqual(valueB, testValueB)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }


    func testParseOptionalAttributeInferred_WithExistingAndExpectedAndValidType_ShouldSucceed() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            var didValidateA = false
            var didValidateB = false

            let startsWithValue: JSON.ParsePredicateClosure<String> = {
                didValidateA = true
                return $0.contains("value")
            }

            let isOdd: JSON.ParsePredicateClosure<Int> = {
                didValidateB = true
                return $0 % 2 == 1
            }

            let valueA: String? = try JSON.parseOptionalAttribute(testKeyA, json: json, where: startsWithValue)
            let valueB: Int? = try JSON.parseOptionalAttribute(testKeyB, json: json, where: isOdd)

            XCTAssertEqual(valueA, testValueA)
            XCTAssertEqual(valueB, testValueB)

            XCTAssert(didValidateA)
            XCTAssert(didValidateB)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalAttributeInferred_WithNonExistentAttributeKey_ShouldSucceed() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            let nonExistent: String? = try JSON.parseOptionalAttribute(nonExistentKey, json: json)

            XCTAssertNil(nonExistent)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalAttributeInferred_WithUnexpectedAttributeType_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            let _: Double? = try JSON.parseOptionalAttribute(testKeyA, json: json)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeType(key, expected, _, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            XCTAssert(expected == Double.self)

            // still not sending in `String`, and the returned `NSTaggedPointerString` is private API, so... 🤷‍♂️
            // XCTAssert(found == String.self)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalAttributeInferred_WithUnexpectedAttributeValue_ShouldFailWithUnexpectedAttributeValue() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        var didValidate = false

        let isEmpty: JSON.ParsePredicateClosure<String> = {
            didValidate = true
            return $0.isEmpty
        }

        do {
            let _: String? = try JSON.parseOptionalAttribute(testKeyA, json: json, where: isEmpty)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeValue(key, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            assertEqualJSONDictionaries(json, errorJSON)
            XCTAssert(didValidate)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // non nil returning parseAPIError

    func testParseOptionalAttributeInferred_WithNonExistentAttributeKeyAndParseAPIClosureReturningError_ShouldFailWithError() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        enum APIError: Swift.Error { case 💥 }
        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in APIError.💥 }

        do {
            let _: String? = try JSON.parseOptionalAttribute(nonExistentKey,
                                                             json: json,
                                                             parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch APIError.💥 {
            // expected error 🎉
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalAttributeInferred_WithUnexpectedAttributeTypeAndParseAPIClosureReturningError_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        enum APIError: Swift.Error { case 💩 }
        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in APIError.💩 }

        do {
            let _: Double? = try JSON.parseOptionalAttribute(testKeyA, json: json, parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch APIError.💩 {
            // expected error 🎉
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // nil returning parseAPIError

    func testParseOptionalAttributeInferred_WithNonExistentAttributeKeyAndParseAPIClosureReturningNil_ShouldSucceed() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in nil }

        do {
            let nonExistent: String? = try JSON.parseOptionalAttribute(nonExistentKey,
                                                                       json: json,
                                                                       parseAPIError: parseAPIError)
            XCTAssertNil(nonExistent)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalAttributeInferred_WithUnexpectedAttributeTypeAndParseAPIClosureReturningNil_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in nil }

        do {
            let _: Double? = try JSON.parseOptionalAttribute(testKeyA, json: json, parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeType(key, expected, _, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            XCTAssert(expected == Double.self)

            // still not sending in `String`, and the returned `NSTaggedPointerString` is private API, so... 🤷‍♂️
            // XCTAssert(found == String.self)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // MARK: - parseRawRepresentableAttribute (inferred type)

    func testParseRawRepresentableAttributeInferred_WithExistingAndExpectedType_ShouldSucceed() {

        do {
            let json = try JSON.parseDictionary(from: testJSONDictData)

            let valueA: TestTypeA = try JSON.parseRawRepresentableAttribute(testKeyA, json: json)
            let valueB: TestTypeB = try JSON.parseRawRepresentableAttribute(testKeyB, json: json)

            XCTAssertEqual(valueA, .valueA)
            XCTAssertEqual(valueB, .valueB)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseRawRepresentableAttributeInferred_WithNonExistentAttributeKey_ShouldFailWithMissingAttribute() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            let _: TestTypeA = try JSON.parseRawRepresentableAttribute(nonExistentKey, json: json)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.missingAttribute(key, json: errorJSON) {
            // expected error 🎉
            assertEqualJSONDictionaries(json, errorJSON)
            XCTAssertEqual(key, nonExistentKey)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseRawRepresentableAttributeInferred_WithUnexpectedAttributeType_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            let _: TestTypeB = try JSON.parseRawRepresentableAttribute(testKeyA, json: json)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeType(key, expected, _, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            XCTAssert(expected == Int.self)

            // still not sending in `String`, and the returned `NSTaggedPointerString` is private API, so... 🤷‍♂️
            // XCTAssert(found == String.self)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseRawRepresentableAttributeInferred_WithUnexpectedAttributeValue_ShouldFailWithUnexpectedAttributeValue() {

        var json = try! JSON.parseDictionary(from: testJSONDictData)
        json[testKeyA] = "invalid"

        do {
            let _: TestTypeA = try JSON.parseRawRepresentableAttribute(testKeyA, json: json)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeValue(key, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // non nil returning parseAPIError

    func testParseRawRepresentableAttributeInferred_WithNonExistentAttributeKeyAndParseAPIClosureReturningError_ShouldFailWithError() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        enum APIError: Swift.Error { case 💥 }
        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in APIError.💥 }

        do {
            let _: TestTypeA = try JSON.parseRawRepresentableAttribute(nonExistentKey,
                                                                       json: json,
                                                                       parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch APIError.💥 {
            // expected error 🎉
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseRawRepresentableAttributeInferred_WithUnexpectedAttributeTypeAndParseAPIClosureReturningError_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        enum APIError: Swift.Error { case 💩 }
        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in APIError.💩 }

        do {
            let _: TestTypeB = try JSON.parseRawRepresentableAttribute(testKeyA,
                                                                       json: json,
                                                                       parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch APIError.💩 {
            // expected error 🎉
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // nil returning parseAPIError

    func testParseRawRepresentableAttributeInferred_WithNonExistentAttributeKeyAndParseAPIClosureReturningNil_ShouldFailWithMissingAttribute() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in nil }

        do {
            let _: TestTypeA = try JSON.parseRawRepresentableAttribute(nonExistentKey,
                                                                       json: json,
                                                                       parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.missingAttribute(key, json: errorJSON) {
            // expected error 🎉
            assertEqualJSONDictionaries(json, errorJSON)
            XCTAssertEqual(key, nonExistentKey)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseRawRepresentableAttributeInferred_WithUnexpectedAttributeTypeAndParseAPIClosureReturningNil_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in nil }

        do {
            let _: TestTypeB = try JSON.parseRawRepresentableAttribute(testKeyA,
                                                                       json: json,
                                                                       parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeType(key, expected, _, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            XCTAssert(expected == Int.self)

            // still not sending in `String`, and the returned `NSTaggedPointerString` is private API, so... 🤷‍♂️
            // XCTAssert(found == String.self)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // MARK: - parseOptionalRawRepresentableAttribute (inferred type)

    func testParseOptionalRawRepresentableAttributeInferred_WithExistingAndExpectedType_ShouldSucceed() {

        do {
            let json = try JSON.parseDictionary(from: testJSONDictData)

            let valueA: TestTypeA? = try JSON.parseOptionalRawRepresentableAttribute(testKeyA, json: json)
            let valueB: TestTypeB? = try JSON.parseOptionalRawRepresentableAttribute(testKeyB, json: json)

            XCTAssertEqual(valueA, .valueA)
            XCTAssertEqual(valueB, .valueB)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalRawRepresentableAttributeInferred_WithNonExistentAttributeKey_ShouldSucceed() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            let nonExistent: TestTypeA? = try JSON.parseOptionalRawRepresentableAttribute(nonExistentKey, json: json)

            XCTAssertNil(nonExistent)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalRawRepresentableAttributeInferred_WithUnexpectedAttributeType_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        do {
            let _: TestTypeB? = try JSON.parseOptionalRawRepresentableAttribute(testKeyA, json: json)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeType(key, expected, _, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            XCTAssert(expected == Int.self)

            // still not sending in `String`, and the returned `NSTaggedPointerString` is private API, so... 🤷‍♂️
            // XCTAssert(found == String.self)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalRawRepresentableAttributeInferred_WithUnexpectedAttributeValue_ShouldFailWithUnexpectedAttributeValue() {

        var json = try! JSON.parseDictionary(from: testJSONDictData)
        json[testKeyA] = "invalid"

        do {
            let _: TestTypeA? = try JSON.parseOptionalRawRepresentableAttribute(testKeyA, json: json)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeValue(key, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // non nil returning parseAPIError

    func testParseOptionalRawRepresentableAttributeInferred_WithNonExistentAttributeKeyAndParseAPIClosureReturningError_ShouldFailWithError() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        enum APIError: Swift.Error { case 💥 }
        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in APIError.💥 }

        do {
            let _: TestTypeA? = try JSON.parseOptionalRawRepresentableAttribute(nonExistentKey,
                                                                                json: json,
                                                                                parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch APIError.💥 {
            // expected error 🎉
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalRawRepresentableAttributeInferred_WithUnexpectedAttributeTypeAndParseAPIClosureReturningError_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        enum APIError: Swift.Error { case 💩 }
        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in APIError.💩 }

        do {
            let _: TestTypeB? = try JSON.parseOptionalRawRepresentableAttribute(testKeyA,
                                                                                json: json,
                                                                                parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch APIError.💩 {
            // expected error 🎉
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // nil returning parseAPIError

    func testParseOptionalRawRepresentableAttributeInferred_WithNonExistentAttributeKeyAndParseAPIClosureReturningNil_ShouldSucceed() {

        let nonExistentKey = "nonExistent"
        let json = try! JSON.parseDictionary(from: testJSONDictData)

        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in nil }

        do {
            let nonExistent: TestTypeA? = try JSON.parseOptionalRawRepresentableAttribute(nonExistentKey,
                                                                                          json: json,
                                                                                          parseAPIError: parseAPIError)
            XCTAssertNil(nonExistent)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalRawRepresentableAttributeInferred_WithUnexpectedAttributeTypeAndParseAPIClosureReturningNil_ShouldFailWithUnexpectedAttributeType() {

        let json = try! JSON.parseDictionary(from: testJSONDictData)

        let parseAPIError: JSON.ParseAPIErrorClosure = { _ in nil }

        do {
            let _: TestTypeB? = try JSON.parseOptionalRawRepresentableAttribute(testKeyA,
                                                                                json: json,
                                                                                parseAPIError: parseAPIError)
            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeType(key, expected, _, errorJSON) {
            // expected error 🎉
            XCTAssertEqual(key, testKeyA)
            XCTAssert(expected == Int.self)

            // still not sending in `String`, and the returned `NSTaggedPointerString` is private API, so... 🤷‍♂️
            // XCTAssert(found == String.self)
            assertEqualJSONDictionaries(json, errorJSON)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseDateAttribute_WithValidIntegerInferredFromFormatter_ShouldReturnAValidDate() {

        let testDate = Date()

        let json = [
            "testDate" : testDate.timeIntervalSince1970
        ]

        do {
            let date = try JSON.parseDateAttribute("testDate",
                                                   json: json,
                                                   formatter: Date.init(timeIntervalSince1970:))

            XCTAssertEqual(date.timeIntervalSince1970, testDate.timeIntervalSince1970)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseDateAttribute_WithValidStringInferredFromFormatter_ShouldReturnAValidDate() {

        let dateFormatter: DateFormatter = {
            $0.dateFormat = "yyyy-MM-dd"
            return $0
        }(DateFormatter())

        let testDateString = dateFormatter.string(from: Date())

        let json = [
            "testDate" : testDateString
        ]

        let testDate = dateFormatter.date(from: testDateString)!

        do {
            let date = try JSON.parseDateAttribute("testDate", json: json, formatter: dateFormatter.date)

            XCTAssertEqual(testDate, date)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseDateAttribute_WithInvalidStringForFormatter_ShouldFailWithUnexpectedAttributeValue() {

        let dateFormatter: DateFormatter = {
            $0.dateFormat = "yyyy-MM-dd"
            return $0
        }(DateFormatter())

        let json = [
            "testDate" : "🤷‍♂️"
        ]

        do {
            let _ = try JSON.parseDateAttribute("testDate", json: json, formatter: dateFormatter.date)

            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeValue(key, json: _) {
            XCTAssertEqual(key, "testDate")
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalDateAttribute_WithUnexistingKey_ShouldReturnNil() {

        let json = [
            "ups" : "🤷‍♂️"
        ]

        do {
            let date = try JSON.parseOptionalDateAttribute("testDate",
                                                           json: json,
                                                           formatter: Date.init(timeIntervalSince1970:))

            XCTAssertNil(date)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalDateAttribute_WithValidIntegerInferredFromFormatter_ShouldReturnAValidDate() {

        let testDate = Date()

        let json = [
            "testDate" : testDate.timeIntervalSince1970
        ]

        do {
            let date = try JSON.parseOptionalDateAttribute("testDate",
                                                           json: json,
                                                           formatter: Date.init(timeIntervalSince1970:))

            XCTAssertNotNil(date)
            XCTAssertEqual(date!, testDate)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalDateAttribute_WithValidStringInferredFromFormatter_ShouldReturnAValidDate() {

        let dateFormatter: DateFormatter = {
            $0.dateFormat = "yyyy-MM-dd"
            return $0
        }(DateFormatter())

        let testDateString = dateFormatter.string(from: Date())

        let json = [
            "testDate" : testDateString
        ]

        let testDate = dateFormatter.date(from: testDateString)!

        do {
            let date = try JSON.parseOptionalDateAttribute("testDate", json: json, formatter: dateFormatter.date)

            XCTAssertNotNil(date)
            XCTAssertEqual(testDate, date)
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    func testParseOptionalDateAttribute_WithInvalidStringForFormatter_ShouldFailWithUnexpectedAttributeValue() {

        let dateFormatter: DateFormatter = {
            $0.dateFormat = "yyyy-MM-dd"
            return $0
        }(DateFormatter())

        let json = [
            "testDate" : "🤷‍♂️"
        ]

        do {
            let _ = try JSON.parseOptionalDateAttribute("testDate", json: json, formatter: dateFormatter.date)

            XCTFail("🔥: unexpected success!")
        } catch let JSON.Error.unexpectedAttributeValue(key, json: _) {
            XCTAssertEqual(key, "testDate")
        } catch {
            XCTFail("🔥: unexpected error \(error)")
        }
    }

    // MARK: - Auxiliary

    private func assertEqualJSONDictionaries(_ lhs: JSON.Dictionary, _ rhs: JSON.Dictionary) {

        XCTAssertEqual(lhs.count, rhs.count)

        guard
            let lhsValueA = lhs[testKeyA] as? String,
            let lhsValueB = lhs[testKeyB] as? Int,
            let rhsValueA = rhs[testKeyA] as? String,
            let rhsValueB = rhs[testKeyB] as? Int
        else {
            return XCTFail("🔥: unexpected json dictionaries!")
        }

        XCTAssertEqual(lhsValueA, rhsValueA)
        XCTAssertEqual(lhsValueB, rhsValueB)
    }
}

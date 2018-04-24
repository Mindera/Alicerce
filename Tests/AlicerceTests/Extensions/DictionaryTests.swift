//
//  DictionaryTests.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 24/04/2018.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class DictionaryTests: XCTestCase {

    // MARK: - Transform

    // MARK: mapKeysAndValues

    func testMapKeysAndValues_WithValueTypeTransformingClosure_ShouldTransformDictionary() {

        let dict = ["a" : 1, "b" : 2, "c" : 3]
        let valueTransform: (String, Int) -> (String, Double) = { ($0, Double($1)) }
        let valueUniquing: (Double, Double) -> (Double) = {
            XCTFail("unexpected duplicate value!")
            return $1
        }

        let mappedDict = dict.mapKeysAndValues(valueTransform, uniquingKeysWith: valueUniquing)

        XCTAssertEqual(mappedDict, ["a" : 1.0, "b" : 2.0, "c" : 3.0])
    }

    func testMapKeysAndValues_WithKeyTransformingClosure_ShouldTransformDictionary() {

        let dict = ["a" : 1, "b" : 2, "c" : 3]
        let keyTransform: (String, Int) -> (UTF8Char, Int) = { ($0.utf8.first!, $1) }
        let valueUniquing: (Int, Int) -> (Int) = {
            XCTFail("unexpected duplicate value!")
            return $1
        }

        let mappedDict = dict.mapKeysAndValues(keyTransform, uniquingKeysWith: valueUniquing)

        XCTAssertEqual(mappedDict, [ "a".utf8.first! : 1, "b".utf8.first! : 2, "c".utf8.first! : 3])
    }

    func testMapKeysAndValues_WithDuplicateKeyTransformingClosure_ShouldTransformDictionaryAndApplyUniquingClosure() {

        let dict = ["a" : 1, "b" : 2, "c" : 3]
        let duplicateKeyTransform: (String, Int) -> (String, Int) = {
            // both "a" and "c" will map to "A", so "c"'s transformed value should prevail (33)
            (["a", "c"].contains($0) ? "A" : $0.uppercased(), $1 * 11)
        }
        let valueUniquing: (Int, Int) -> (Int) = { current, new in new }

        let mappedDict = dict.mapKeysAndValues(duplicateKeyTransform, uniquingKeysWith: valueUniquing)

        XCTAssertEqual(mappedDict, [ "A" : 33, "B" : 22])
    }

    // MARK: flattened

    func testFlattened_withNoNestedDictionaries_ShouldReturnSameDictionary() {

        let dict = ["a" : 1, "b" : 2, "c" : 3]

        let flattenedDict = dict.flattened()

        XCTAssertEqual(flattenedDict, dict)
    }

    func testFlattened_withNestedDictionaries_ShouldReturnFlattenedDictionary() {

        let AADict = ["aaa" : 11, "aaaa" : 111]
        let aDict: [String : Any] = ["A" : 1, "AA" : AADict]
        let dict: [String : Any] = ["a" : aDict, "b" : 2, "c" : 3]

        let flattenedDict = dict.flattened()

        guard let stringIntFlattenedDict = flattenedDict as? [String : Int] else {
            return XCTFail("🔥: returned flattened dictionary has invalid type!")
        }

        XCTAssertEqual(stringIntFlattenedDict, ["a.A" : 1, "a.AA.aaa" : 11, "a.AA.aaaa" : 111,  "b" : 2, "c" : 3])
    }

    func testFlattened_withNestedDictionariesWithInvalidType_ShouldReturnFlattenedDictionaryNotNestingInvalidTypeDictionaries() {

        let cDict = [3.0 : 33, 30.0 : 333]
        let aDict: [String : Any] = ["A" : 1, "AA" : 11]
        let dict: [String : Any] = ["a" : aDict, "b" : 2, "c" : cDict]

        let flattenedDict = dict.flattened()

        XCTAssertEqual(flattenedDict["a.A"] as? Int, 1)
        XCTAssertEqual(flattenedDict["a.AA"] as? Int, 11)
        XCTAssertEqual(flattenedDict["b"] as? Int ?? 0, 2)
        XCTAssertEqual(flattenedDict["c"] as? [Double : Int], cDict)
    }

    func testFlattened_withEmptyDictionary_ShouldReturnEmptyDictionary() {

        let dict: [String : Int] = [:]

        let flattenedDict = dict.flattened()

        XCTAssertEqual(flattenedDict, [:])
    }

    // MARK: - Remove values

    // MARK: removingValuesForKeys

    func testRemovingValuesForKeys_WithKeySequenceMatchingKeys_ShouldRemoveMatchingKeysFromDictionary() {

        let dict = ["a" : 1, "b" : 2, "c" : 3]
        let keysToRemove = ["a", "c", "x"]

        let newDict = dict.removingValues(forKeys: keysToRemove)

        XCTAssertEqual(newDict, ["b" : 2])
    }

    func testRemovingValuesForKeys_WithKeySequenceNotMatchingKeys_ShouldNotRemoveKeysFromDictionary() {

        let dict = ["a" : 1, "b" : 2, "c" : 3]
        let keysToRemove = ["x", "y"]

        let newDict = dict.removingValues(forKeys: keysToRemove)

        XCTAssertEqual(newDict, dict)
    }

    func testRemovingValuesForKeys_WithEmptyKeySequence_ShouldNotRemoveKeysFromDictionary() {

        let dict = ["a" : 1, "b" : 2, "c" : 3]
        let keysToRemove: [String] = []

        let newDict = dict.removingValues(forKeys: keysToRemove)

        XCTAssertEqual(newDict, dict)
    }

    // MARK: removeValuesForKeys

    func testRemoveValuesForKeys_WithKeySequenceMatchingKeys_ShouldRemoveMatchingKeysFromDictionaryAndReturnKeyValueDict() {

        var dict = ["a" : 1, "b" : 2, "c" : 3]
        let keysToRemove = ["a", "c", "x"]

        let removedKeyValues = dict.removeValues(forKeys: keysToRemove)

        XCTAssertEqual(dict, ["b" : 2])
        XCTAssertEqual(removedKeyValues.count, keysToRemove.count)
        XCTAssertEqual(removedKeyValues["a"], 1)
        XCTAssertEqual(removedKeyValues["c"], 3)
        XCTAssertEqual(removedKeyValues["x"], .some(nil))
    }

    func testRemoveValuesForKeys_WithKeySequenceNotMatchingKeys_ShouldNotRemoveKeysFromDictionaryAndReturnEmptyKeyValueDict() {

        var dict = ["a" : 1, "b" : 2, "c" : 3]
        let keysToRemove = ["x", "y"]

        let removedKeyValues = dict.removeValues(forKeys: keysToRemove)

        XCTAssertEqual(dict, ["a" : 1, "b" : 2, "c" : 3])
        XCTAssertEqual(removedKeyValues.count, keysToRemove.count)
        XCTAssertEqual(removedKeyValues["x"], .some(nil))
        XCTAssertEqual(removedKeyValues["y"], .some(nil))
    }

    func testRemoveValuesForKeys_WithEmptyKeySequence_ShouldNotRemoveKeysFromDictionaryAndReturnEmptyKeyValueDict() {

        var dict = ["a" : 1, "b" : 2, "c" : 3]
        let keysToRemove: [String] = []

        let removedKeyValues = dict.removeValues(forKeys: keysToRemove)
        
        XCTAssertEqual(dict, ["a" : 1, "b" : 2, "c" : 3])
        XCTAssert(removedKeyValues.isEmpty)
    }

    // MARK: - Get values

    // MARK: multi subscript varargs

    func testMultiSubscriptVarArgs_WithSequenceMatchingKeys_ShouldReturnOptionalValueArrayWithMathingAndNotMatchingValuesInOrder() {

        let dict = ["a" : 1, "b" : 2, "c" : 3]

        let values = dict["a", "b", "x"]

        XCTAssertEqual(values.count, 3)
        XCTAssertEqual(values[0], 1)
        XCTAssertEqual(values[1], 2)
        XCTAssertEqual(values[2], nil)
    }

    func testMultiSubscriptVarArgs_WithSequenceNotMatchingKeys_ShouldReturnOptionalValueArrayWithOnlyNotMatchingValues() {

        let dict = ["a" : 1, "b" : 2, "c" : 3]

        let values = dict["x", "y"]

        XCTAssertEqual(values.count, 2)
        XCTAssertEqual(values[0], nil)
        XCTAssertEqual(values[1], nil)
    }

    // MARK: multi subscript Sequence

    func testMultiSubscriptSequence_WithSequenceMatchingKeys_ShouldReturnOptionalValueArrayWithMathingAndNotMatchingValuesInOrder() {

        let dict = ["a" : 1, "b" : 2, "c" : 3]
        let keysToGet = ["a", "b", "x"]
        let values = dict[keysToGet]

        XCTAssertEqual(values.count, keysToGet.count)
        XCTAssertEqual(values[0], 1)
        XCTAssertEqual(values[1], 2)
        XCTAssertEqual(values[2], nil)
    }

    func testMultiSubscriptSequence_WithSequenceNotMatchingKeys_ShouldReturnOptionalValueArrayWithOnlyNotMatchingValues() {

        let dict = ["a" : 1, "b" : 2, "c" : 3]
        let keysToGet = ["x", "y"]
        let values = dict["x", "y"]

        XCTAssertEqual(values.count, keysToGet.count)
        XCTAssertEqual(values[0], nil)
        XCTAssertEqual(values[1], nil)
    }

}

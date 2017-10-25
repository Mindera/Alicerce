//
//  MappableTestCase.swift
//  Alicerce
//
//  Created by Luís Afonso on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest

@testable import Alicerce

final class MappableTestCase: XCTestCase {

    enum RawMappable: String, Mappable {
        case 💪
    }

    // MARK: - Success tests

    func testModel_WhenInputObjectIsValid_ShouldReturnAFilledModel() {
        let aValidDict = ["data" : "👍"]

        do {
            let mappedModel = try MappableModel.model(from: aValidDict)

            XCTAssertEqual(mappedModel, MappableModel(data: "👍"))
        } catch {
            XCTFail("🔥 unexpected error 👉 \(error) 😱")
        }
    }

    func testJSON_WhenInputIsValid_ShouldReturnAFilledJSONObject() {
        let testJSON = ["data" : "👍" ]

        let model = MappableModel(data: "👍")
        let json = model.json()

        guard let generatedJSON = json as? [String : String] else {
            return XCTFail("🔥: unexpected generated JSON!")
        }

        for (test, generated) in zip(testJSON, generatedJSON) {
            XCTAssertEqual(test.key, generated.key)
            XCTAssertEqual(test.value, generated.value)
        }
    }

    func testModelArray_WhenInputArrayIsValid_ShouldReturnAFilledModelArray() {
        let aValidDictArray = [
            ["data" : "👍"],
            ["data" : "👌"],
        ]

        do {
            let mappedModels = try [MappableModel].model(from: aValidDictArray)

            XCTAssertEqual(mappedModels, [MappableModel(data: "👍"), MappableModel(data: "👌")])
        } catch {
            XCTFail("🔥 unexpected error 👉 \(error) 😱")
        }
    }

    func testJSONArray_WhenInputIsValid_ShouldReturnAFilledJSONArray() {
        let testJSON = [
            ["data" : "👍"],
            ["data" : "👌"],
        ]

        let models = [MappableModel(data: "👍"), MappableModel(data: "👌")]
        let json = models.json()

        XCTAssertEqual(json.count, 2)
        XCTAssertEqual(testJSON.count, json.count)

        guard let generatedJSON = json as? [[String : String]] else {
            return XCTFail("🔥: unexpected generated JSON!")
        }

        for (test, generated) in zip(testJSON, generatedJSON) {
            XCTAssertEqual(test, generated)
        }
    }

    func testModelRawRepresentable_WhenInputObjectIsValid_ShouldReturnAFilledModel() {
        let aValidValue = "💪"

        do {
            let mappedModel = try RawMappable.model(from: aValidValue)

            XCTAssertEqual(mappedModel, RawMappable.💪)
        } catch {
            XCTFail("🔥 unexpected error 👉 \(error) 😱")
        }
    }

    func testJSONRawRepresentable_WhenInputObjectIsValid_ShouldReturnAFilledJSONObject() {
        let testJSON = "💪"

        let model = RawMappable.💪
        let json = model.json()

        guard let generatedJSON = json as? String else {
            return XCTFail("🔥: unexpected generated JSON!")
        }

         XCTAssertEqual(testJSON, generatedJSON)
    }

    // MARK: - Error tests

    func testModel_WhenInputObjectIsInvalid_ShouldReturnAnError() {
        let anObject = "☠️"

        do {
            let _ = try MappableModel.model(from: anObject)

            XCTFail("🔥 It didn't throw error 😱")
        } catch JSON.Error.unexpectedType {
            // 🤠 well done sir
        } catch {
            XCTFail("🔥 unexpected error 👉 \(error) 😱")
        }
    }

    func testModel_WhenInputObjectIsValidButDontContainsRequiredElement_ShouldReturnAnError() {
        let aDict = ["☠️" : "💥"]

        do {
            let _ = try MappableModel.model(from: aDict)

            XCTFail("🔥 It didn't throw an error 😱")
        } catch let JSON.Error.missingAttribute(key, _) {
            XCTAssertEqual(key, "data")
        } catch {
            XCTFail("🔥 unexpected error 👉 \(error) 😱")
        }
    }

    func testModelArray_WhenInputArrayIsInvalid_ShouldReturnAnError() {
        let anInvalidArray = [
            ["☠️"],
            ["👻"],
        ]

        do {
            let _ = try [MappableModel].model(from: anInvalidArray)

            XCTFail("🔥 It didn't throw an error 😱")
        } catch JSON.Error.unexpectedType {
            // 🤠 well done sir
        } catch {
            XCTFail("🔥 unexpected error 👉 \(error) 😱")
        }
    }

    func testModelArray_WhenInputObjectIsValidButDontContainsRequiredElement_ShouldReturnAnError() {
        let anInvalidArray = [
            ["☠️" : "💥"],
            ["👻" : "💥"]
        ]

        do {
            let _ = try [MappableModel].model(from: anInvalidArray)

            XCTFail("🔥 It didn't throw an error 😱")
        } catch let JSON.Error.missingAttribute(key, _) {
            XCTAssertEqual(key, "data")
        } catch {
            XCTFail("🔥 unexpected error 👉 \(error) 😱")
        }
    }

    func testModelRawRepresentable_WhenInputTypeIsInvalid_ShouldReturnAnError() {
        let anInvalidTypeValue = 1337

        do {
            let _ = try RawMappable.model(from: anInvalidTypeValue)

            XCTFail("🔥 It didn't throw an error 😱")
        } catch let JSON.Error.unexpectedType(expected, found) {
            // 🤠 well done sir
            XCTAssert(expected == RawMappable.RawValue.self)
            XCTAssert(found == Int.self)
        } catch {
            XCTFail("🔥 unexpected error 👉 \(error) 😱")
        }
    }

    func testModelRawRepresentable_WhenInputValueIsInvalid_ShouldReturnAnError() {
        let anInvalidValue = "💩"

        do {
            let _ = try RawMappable.model(from: anInvalidValue)

            XCTFail("🔥 It didn't throw an error 😱")
        } catch let JSON.Error.unexpectedRawValue(type, found) {
            XCTAssert(type == RawMappable.self)
            XCTAssertEqual(found as? String, anInvalidValue)
        } catch {
            XCTFail("🔥 unexpected error 👉 \(error) 😱")
        }
    }

}

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

    // MARK: - Success tests

    func testModel_WhenInputObjectIsValid_ShouldReturnAFilledModel() {
        let aValidDict = [
            "data" : "👍"
        ]

        do {
            let mappedModel = try MappableModel.model(from: aValidDict)

            XCTAssertEqual(mappedModel, MappableModel(data: "👍"))
        } catch {
            XCTFail("🔥 unexpected error 👉 \(error) 😱")
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
        let aDict = [
            "☠️" : "💥"
        ]

        do {
            let _ = try MappableModel.model(from: aDict)

            XCTFail("🔥 It didn't throw an error 😱")
        } catch let JSON.Error.missingAttribute(key, _) {
            XCTAssertEqual(key, "data")
        } catch {
            XCTFail("🔥 unexpected error 👉 \(error) 😱")
        }
    }

    func testModelArray_WhenInputArrayIsInValid_ShouldReturnAnError() {
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

}

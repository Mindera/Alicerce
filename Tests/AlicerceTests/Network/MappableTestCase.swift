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

    func testModel_WhenInputObjectIsValid_ItShouldReturnAFilledModel() {
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

    // MARK: - Error tests

    func testModel_WhenInputObjectIsInvalid_ItShouldReturnAnError() {
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

    func testModel_WhenInputObjectIsValidButDontContainsRequiredElement_ItShouldReturnAnError() {
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
}

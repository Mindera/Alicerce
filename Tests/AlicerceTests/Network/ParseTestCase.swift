//
//  ParseTestCase.swift
//  Alicerce
//
//  Created by Luís Portela on 12/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest

@testable import Alicerce

final class ParseTestCase: XCTestCase {

    // MARK: - Success tests

    func testJson_WhenDataIsValid_ItShouldReturnValidObject() {
        let jsonData = try! JSONSerialization.data(withJSONObject: ["data" : "👍"], options: [])

        do {
            let parsedModel: MappableModel = try Parse.json(data: jsonData)

            XCTAssertEqual(parsedModel.data, "👍")
        } catch {
            XCTFail("🔥 received unexpected error 👉 \(error) 😱")
        }
    }

    func testImage_WhenDataIsValid_ItShouldReturnValidImage() {
        let imageData = dataFromFile(withBundleClass: ParseTestCase.self, name: "mr-minder", type: "png")

        do {
            let _ = try Parse.image(data: imageData)
        } catch Parse.Error.serialization(_) {
            XCTFail("🔥 shouldn't have failed image serialization 😱")
        } catch {
            XCTFail("🔥 received unexpected error 👉 \(error) 😱")
        }
    }

    // MARK: - Error tests

    func testJson_WhenInvalidJSON_ItShouldThrowASerializationErro() {
        let jsonData = "🚫".data(using: .utf8)!

        do {
            let _: MappableModel = try Parse.json(data: jsonData)
        } catch Parse.Error.serialization(_) {
            // 🤠 well done sir
        } catch {
            XCTFail("🔥 received unexpected error 👉 \(error) 😱")
        }
    }

    func testJson_WhenMappingFails_ItShouldThrowAMappableError() {
        let jsonData = try! JSONSerialization.data(withJSONObject: ["key" : "🚫"], options: [])

        do {
            let _: MappableModel = try Parse.json(data: jsonData)
        } catch Parse.Error.mapping(_) {
            // 🤠 well done sir
        } catch {
            XCTFail("🔥 received unexpected error 👉 \(error) 😱")
        }
    }

    func testImage_WhenDataIsInvalid_ItShouldThrowASerializationError() {
        let imageData = "🤓".data(using: .utf8)!

        do {
            let _ = try Parse.image(data: imageData)
        } catch Parse.Error.serialization(_) {
            // 🤠 well done sir
        } catch {
            XCTFail("🔥 received unexpected error 👉 \(error) 😱")
        }
    }
}

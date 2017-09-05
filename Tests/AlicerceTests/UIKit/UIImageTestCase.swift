//
//  UIImageTestCase.swift
//  Alicerce
//
//  Created by Luís Portela on 03/08/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
import UIKit

@testable import Alicerce

final class UIImageTestCase: XCTestCase {

    func testOriginal_WhenHasImage_ItShouldReturnTheOriginalImage() {
        let mrMinder = imageFromFile(withBundleClass: UIImageTestCase.self,
                                     name: "mr-minder",
                                     type: "png")

        let mrMinderOriginal = mrMinder.original

        XCTAssertEqual(mrMinderOriginal.renderingMode, .alwaysOriginal)
    }

    func testTemplate_WhenHasImage_ItShouldReturnTheTemplateImage() {
        let mrMinder = imageFromFile(withBundleClass: UIImageTestCase.self,
                                     name: "mr-minder",
                                     type: "png")

        let mrMinderTemplate = mrMinder.template

        XCTAssertEqual(mrMinderTemplate.renderingMode, .alwaysTemplate)
    }
}

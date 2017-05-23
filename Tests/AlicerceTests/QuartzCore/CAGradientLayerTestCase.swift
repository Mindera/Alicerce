//
//  CAGradientLayerTestCase.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 22/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
import QuartzCore
@testable import Alicerce

class CAGradientLayerTestCase: XCTestCase {

    func testLayer_WithGivenColor_ShouldCreateLayerWithCorrectColor() {
        let testColors: [UIColor] = [.white, .black]
        let testLocations: [Float] = [0.1337, 1.0]
        let testOpacity: Float = 0.1337
        let testStartPoint = CGPoint(x: 0, y: 0.1337)
        let testEndPoint = CGPoint(x: 0.1337, y: 1.0)

        let layer = CAGradientLayer.layer(colors: testColors,
                                          locations: testLocations,
                                          opacity: testOpacity,
                                          startPoint: testStartPoint,
                                          endPoint: testEndPoint)

        guard let layerColors = layer.colors as? [CGColor] else {
            return XCTFail("🔥: unexpected layer color array type!")
        }

        guard let locations = layer.locations else {
            return XCTFail("🔥: layer locations can't be nil!")
        }

        XCTAssertEqual(layerColors, testColors.map { $0.cgColor })
        XCTAssertEqual(locations, testLocations.map { NSNumber(value: $0) })
        XCTAssertEqual(layer.opacity, testOpacity)
        XCTAssertEqual(layer.startPoint, testStartPoint)
        XCTAssertEqual(layer.endPoint, testEndPoint)
    }
}

//
//  StringAttributesTestCase.swift
//  AlicerceTests
//
//  Created by Tiago Veloso on 17/02/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class StringAttributesTestCase: XCTestCase {

    func test_font() {

        let attributes = StringAttributes({
            $0.font = .boldSystemFont(ofSize: 24)
        })

        XCTAssert(attributes[NSAttributedStringKey.font] as? UIFont == UIFont.boldSystemFont(ofSize: 24))
    }

    func test_foregroundColor() {

        let attributes = StringAttributes({
            $0.foregroundColor = .white
        })

        XCTAssert(attributes[NSAttributedStringKey.foregroundColor] as? UIColor == .white)
    }

    func test_backgroundColor() {

        let attributes = StringAttributes({
            $0.backgroundColor = .blue
        })

        XCTAssert(attributes[NSAttributedStringKey.backgroundColor] as? UIColor == .blue)
    }

    func test_paragraphStyle() {

        let attributes = StringAttributes({
            $0.paragraphStyle = NSParagraphStyle().with(transformer: {
                $0.lineBreakMode = .byWordWrapping
            })
        })

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping

        XCTAssert(attributes[NSAttributedStringKey.paragraphStyle] as? NSParagraphStyle == paragraphStyle.copy() as? NSParagraphStyle)
    }

    func test_ligature() {

        let attributes = StringAttributes({
            $0.ligature = 10
        })

        XCTAssert(attributes[NSAttributedStringKey.ligature] as? Int == 10)
    }

    func test_kern() {

        let attributes = StringAttributes({
            $0.kern = 10.0
        })

        XCTAssert(attributes[NSAttributedStringKey.kern] as? CGFloat == 10.0)
    }

    func test_strikethroughStyle() {

        let attributes = StringAttributes({
            $0.strikethroughStyle = NSUnderlineStyle.patternDashDotDot
        })

        XCTAssert(attributes[NSAttributedStringKey.strikethroughStyle] as? Int == NSUnderlineStyle.patternDashDotDot.rawValue)
    }

    func test_strikethroughColor() {

        let attributes = StringAttributes({
            $0.strikethroughColor = .green
        })

        XCTAssert(attributes[NSAttributedStringKey.strikethroughColor] as? UIColor == .green)
    }

    func test_underlineStyle() {

        let attributes = StringAttributes({
            $0.underlineStyle = NSUnderlineStyle.patternDash
        })

        XCTAssert(attributes[NSAttributedStringKey.underlineStyle] as? Int == NSUnderlineStyle.patternDash.rawValue)
    }

    func test_underlineColor() {

        let attributes = StringAttributes({
            $0.underlineColor = .cyan
        })

        XCTAssert(attributes[NSAttributedStringKey.underlineColor] as? UIColor == .cyan)
    }

    func test_strokeColor() {

        let attributes = StringAttributes({
            $0.strokeColor = .brown
        })

        XCTAssert(attributes[NSAttributedStringKey.strokeColor] as? UIColor == .brown)
    }

    func test_strokeWidth() {

        let attributes = StringAttributes({
            $0.strokeWidth = 4
        })

        XCTAssert(attributes[NSAttributedStringKey.strokeWidth] as? Int == 4)
    }

    func test_shadow() {

        let shadow = NSShadow()
        shadow.shadowColor = UIColor.green

        let attributes = StringAttributes({
            $0.shadow = shadow
        })

        XCTAssert(attributes[NSAttributedStringKey.shadow] as? NSShadow == shadow)
    }

    func test_textEffect() {

        let attributes = StringAttributes({
            $0.textEffect = .letterpressStyle
        })

        XCTAssert(attributes[NSAttributedStringKey.textEffect] as? String == NSAttributedString.TextEffectStyle.letterpressStyle.rawValue)
    }

    func test_link() {

        let url = URL(string: "http://google.com")

        let attributes = StringAttributes({
            $0.link = url
        })

        XCTAssert(attributes[NSAttributedStringKey.link] as? URL == url)
    }

    func test_baselineOffset() {

        let attributes = StringAttributes({
            $0.baselineOffset = 10.0
        })

        XCTAssert(attributes[NSAttributedStringKey.baselineOffset] as? CGFloat == 10.0)
    }

    func test_obliqueness() {

        let attributes = StringAttributes({
            $0.obliqueness = 13.0
        })

        XCTAssert(attributes[NSAttributedStringKey.obliqueness] as? CGFloat == 13.0)
    }

    func test_expansion() {

        let attributes = StringAttributes({
            $0.expansion = 18.0
        })

        XCTAssert(attributes[NSAttributedStringKey.expansion] as? CGFloat == 18.0)
    }

    func test_verticalGlyphForm() {

        let attributes = StringAttributes({
            $0.verticalGlyphForm = 1
        })

        XCTAssert(attributes[NSAttributedStringKey.verticalGlyphForm] as? Int == 1)
    }

    func test_alignment() {

        let attributes = StringAttributes().alignment(.left)

        let paragraph = attributes[NSAttributedStringKey.paragraphStyle] as? NSParagraphStyle

        XCTAssert(paragraph?.alignment == .left)
    }
}

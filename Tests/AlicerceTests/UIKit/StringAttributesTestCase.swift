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
        XCTAssert(attributes[NSAttributedStringKey.font] as? UIFont == attributes.font)
    }

    func test_foregroundColor() {

        let attributes = StringAttributes({
            $0.foregroundColor = .white
        })

        XCTAssert(attributes[NSAttributedStringKey.foregroundColor] as? UIColor == .white)
        XCTAssert(attributes[NSAttributedStringKey.foregroundColor] as? UIColor == attributes.foregroundColor)
    }

    func test_backgroundColor() {

        let attributes = StringAttributes({
            $0.backgroundColor = .blue
        })

        XCTAssert(attributes[NSAttributedStringKey.backgroundColor] as? UIColor == .blue)
        XCTAssert(attributes[NSAttributedStringKey.backgroundColor] as? UIColor == attributes.backgroundColor)
    }

    func test_paragraphStyle() {

        let attributes = StringAttributes({
            $0.paragraphStyle = NSParagraphStyle().with(transformer: {
                $0.lineBreakMode = .byWordWrapping
            })
        })

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping

        XCTAssert(attributes[NSAttributedStringKey.paragraphStyle] as? NSParagraphStyle == paragraphStyle)
        XCTAssert(attributes[NSAttributedStringKey.paragraphStyle] as? NSParagraphStyle == attributes.paragraphStyle)
    }

    func test_ligature() {

        let attributes = StringAttributes({
            $0.ligature = 10
        })

        XCTAssert(attributes[NSAttributedStringKey.ligature] as? NSNumber == 10)
        XCTAssert(attributes[NSAttributedStringKey.ligature] as? NSNumber == attributes.ligature)
    }

    func test_kern() {

        let attributes = StringAttributes({
            $0.kern = 10.0
        })

        XCTAssert(attributes[NSAttributedStringKey.kern] as? CGFloat == 10.0)
        XCTAssert(attributes[NSAttributedStringKey.kern] as? CGFloat == attributes.kern)
    }

    func test_strikethroughStyle() {

        let attributes = StringAttributes({
            $0.strikethroughStyle = NSUnderlineStyle.patternDashDotDot
        })

        XCTAssert(attributes[NSAttributedStringKey.strikethroughStyle] as? Int == NSUnderlineStyle.patternDashDotDot.rawValue)
        XCTAssert(attributes[NSAttributedStringKey.strikethroughStyle] as? Int == attributes.strikethroughStyle?.rawValue)
    }

    func test_strikethroughColor() {

        let attributes = StringAttributes({
            $0.strikethroughColor = .green
        })

        XCTAssert(attributes[NSAttributedStringKey.strikethroughColor] as? UIColor == .green)
        XCTAssert(attributes[NSAttributedStringKey.strikethroughColor] as? UIColor == attributes.strikethroughColor)
    }

    func test_underlineStyle() {

        let attributes = StringAttributes({
            $0.underlineStyle = NSUnderlineStyle.patternDash
        })

        XCTAssert(attributes[NSAttributedStringKey.underlineStyle] as? Int == NSUnderlineStyle.patternDash.rawValue)
        XCTAssert(attributes[NSAttributedStringKey.underlineStyle] as? Int == attributes.underlineStyle?.rawValue)
    }

    func test_underlineColor() {

        let attributes = StringAttributes({
            $0.underlineColor = .cyan
        })

        XCTAssert(attributes[NSAttributedStringKey.underlineColor] as? UIColor == .cyan)
        XCTAssert(attributes[NSAttributedStringKey.underlineColor] as? UIColor == attributes.underlineColor)
    }

    func test_strokeColor() {

        let attributes = StringAttributes({
            $0.strokeColor = .brown
        })

        XCTAssert(attributes[NSAttributedStringKey.strokeColor] as? UIColor == .brown)
        XCTAssert(attributes[NSAttributedStringKey.strokeColor] as? UIColor == attributes.strokeColor)
    }

    func test_strokeWidth() {

        let attributes = StringAttributes({
            $0.strokeWidth = 4
        })

        XCTAssert(attributes[NSAttributedStringKey.strokeWidth] as? NSNumber == 4)
        XCTAssert(attributes[NSAttributedStringKey.strokeWidth] as? NSNumber == attributes.strokeWidth)
    }

    func test_shadow() {

        let shadow = NSShadow()
        shadow.shadowColor = UIColor.green

        let attributes = StringAttributes({
            $0.shadow = shadow
        })

        XCTAssert(attributes[NSAttributedStringKey.shadow] as? NSShadow == shadow)
        XCTAssert(attributes[NSAttributedStringKey.shadow] as? NSShadow == attributes.shadow)
    }

    func test_textEffect() {

        let attributes = StringAttributes({
            $0.textEffect = .letterpressStyle
        })

        XCTAssert(attributes[NSAttributedStringKey.textEffect] as? String == NSAttributedString.TextEffectStyle.letterpressStyle.rawValue)
        XCTAssert(attributes[NSAttributedStringKey.textEffect] as? String == attributes.textEffect?.rawValue)
    }

    func test_link() {

        let url = URL(string: "http://google.com")

        let attributes = StringAttributes({
            $0.link = url
        })

        XCTAssert(attributes[NSAttributedStringKey.link] as? URL == url)
        XCTAssert(attributes[NSAttributedStringKey.link] as? URL == attributes.link)
    }

    func test_baselineOffset() {

        let attributes = StringAttributes({
            $0.baselineOffset = 10.0
        })

        XCTAssert(attributes[NSAttributedStringKey.baselineOffset] as? NSNumber == 10.0)
        XCTAssert(attributes[NSAttributedStringKey.baselineOffset] as? NSNumber == attributes.baselineOffset)
    }

    func test_obliqueness() {

        let attributes = StringAttributes({
            $0.obliqueness = 13.0
        })

        XCTAssert(attributes[NSAttributedStringKey.obliqueness] as? NSNumber == 13.0)
        XCTAssert(attributes[NSAttributedStringKey.obliqueness] as? NSNumber == attributes.obliqueness)
    }

    func test_expansion() {

        let attributes = StringAttributes({
            $0.expansion = 18.0
        })

        XCTAssert(attributes[NSAttributedStringKey.expansion] as? NSNumber == 18.0)
        XCTAssert(attributes[NSAttributedStringKey.expansion] as? NSNumber == attributes.expansion)
    }

    func test_verticalGlyphForm() {

        let attributes = StringAttributes({
            $0.verticalGlyphForm = 1
        })

        XCTAssert(attributes[NSAttributedStringKey.verticalGlyphForm] as? NSNumber == 1)
        XCTAssert(attributes[NSAttributedStringKey.verticalGlyphForm] as? NSNumber == attributes.verticalGlyphForm)
    }

    func test_alignment() {

        let attributes = StringAttributes().alignment(.left)

        let paragraph = attributes[NSAttributedStringKey.paragraphStyle] as? NSParagraphStyle

        XCTAssert(paragraph?.alignment == .left)
    }

    func test_string_builder() {

        let string = "Hello World!!".with(StringAttributes({
            $0.foregroundColor = .red
            $0.backgroundColor = .white
        }))

        let attributes = string.attributes(at: 0, longestEffectiveRange: nil, in: NSRange(location: 0, length: string.length))

        XCTAssert(attributes[NSAttributedStringKey.foregroundColor] as? UIColor == .red)
        XCTAssert(attributes[NSAttributedStringKey.backgroundColor] as? UIColor == .white)
    }
}

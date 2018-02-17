//
//  StringAttributes.swift
//  Alicerce
//
//  Created by Tiago Veloso on 17/02/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

// Credits to: Dmitry Nesterenko
// https://github.com/chebur/StringAttributes

import UIKit

public typealias StringAttributes = [NSAttributedStringKey: Any]

/// This extension allows for an easy initialization of [NSAttributedStringKey: Any]
/// for use with NSAttributedStrings.
///
/// This also adds type-safety when adding attributes to the dictionary
extension Dictionary where Key == NSAttributedStringKey, Value == Any {

    /// StringAttributes init method using a builder pattern
    ///
    /// - Parameter builder: the builder to initialize the StringAttributes dictionaty
    public init(_ builder: (inout StringAttributes) -> ()) {
        self.init()
        builder(&self)
    }

    public var font: UIFont? {
        get {
            return self[NSAttributedStringKey.font] as? UIFont
        }
        set {
            self[NSAttributedStringKey.font] = newValue
        }
    }

    public var paragraphStyle: NSParagraphStyle? {
        get {
            return self[NSAttributedStringKey.paragraphStyle] as? NSParagraphStyle
        }
        set {
            self[NSAttributedStringKey.paragraphStyle] = newValue
        }
    }

    public var foregroundColor: UIColor? {
        get {
            return self[NSAttributedStringKey.foregroundColor] as? UIColor
        }
        set {
            self[NSAttributedStringKey.foregroundColor] = newValue
        }
    }

    public var backgroundColor: UIColor? {
        get {
            return self[NSAttributedStringKey.backgroundColor] as? UIColor
        }
        set {
            self[NSAttributedStringKey.backgroundColor] = newValue
        }
    }

    public var ligature: NSNumber? {
        get {
            return self[NSAttributedStringKey.ligature] as? NSNumber
        }
        set {
            self[NSAttributedStringKey.ligature] = newValue
        }
    }

    public var kern: CGFloat? {
        get {
            return self[NSAttributedStringKey.kern] as? CGFloat
        }
        set {
            self[NSAttributedStringKey.kern] = newValue
        }
    }

    public var strikethroughStyle: NSUnderlineStyle? {
        get {
            guard let rawValue = self[NSAttributedStringKey.strikethroughStyle] as? Int else { return nil }

            return NSUnderlineStyle(rawValue: rawValue)
        }
        set {
            self[NSAttributedStringKey.strikethroughStyle] = newValue?.rawValue
        }
    }

    public var strikethroughColor: UIColor? {
        get {
            return self[NSAttributedStringKey.strikethroughColor] as? UIColor
        }
        set {
            self[NSAttributedStringKey.strikethroughColor] = newValue
        }
    }

    public var underlineStyle: NSUnderlineStyle? {
        get {
            guard let rawValue = self[NSAttributedStringKey.underlineStyle] as? Int else { return nil }

            return NSUnderlineStyle(rawValue: rawValue)
        }
        set {
            self[NSAttributedStringKey.underlineStyle] = newValue?.rawValue
        }
    }

    public var underlineColor: UIColor? {
        get {
            return self[NSAttributedStringKey.underlineColor] as? UIColor
        }
        set {
            self[NSAttributedStringKey.underlineColor] = newValue
        }
    }

    public var strokeColor: UIColor? {
        get {
            return self[NSAttributedStringKey.strokeColor] as? UIColor
        }
        set {
            self[NSAttributedStringKey.strokeColor] = newValue
        }
    }

    public var strokeWidth: NSNumber? {
        get {
            return self[NSAttributedStringKey.strokeWidth] as? NSNumber
        }
        set {
            self[NSAttributedStringKey.strokeWidth] = newValue
        }
    }

    public var shadow: NSShadow? {
        get {
            return self[NSAttributedStringKey.shadow] as? NSShadow
        }
        set {
            self[NSAttributedStringKey.shadow] = newValue
        }
    }

    public var textEffect: NSAttributedString.TextEffectStyle? {
        get {
            guard let string = self[NSAttributedStringKey.textEffect] as? String else { return nil }

            return NSAttributedString.TextEffectStyle(rawValue: string)
        }
        set {
            self[NSAttributedStringKey.textEffect] = newValue?.rawValue
        }
    }

    public var link: URL? {
        get {
            return self[NSAttributedStringKey.link] as? URL
        }
        set {
            self[NSAttributedStringKey.link] = newValue
        }
    }

    public var baselineOffset: NSNumber? {
        get {
            return self[NSAttributedStringKey.baselineOffset] as? NSNumber
        }
        set {
            self[NSAttributedStringKey.baselineOffset] = newValue
        }
    }

    public var obliqueness: NSNumber? {
        get {
            return self[NSAttributedStringKey.obliqueness] as? NSNumber
        }
        set {
            self[NSAttributedStringKey.obliqueness] = newValue
        }
    }

    public var expansion: NSNumber? {
        get {
            return self[NSAttributedStringKey.expansion] as? NSNumber
        }
        set {
            self[NSAttributedStringKey.expansion] = newValue
        }
    }

    public var verticalGlyphForm: NSNumber? {
        get {
            return self[NSAttributedStringKey.verticalGlyphForm] as? NSNumber
        }
        set {
            self[NSAttributedStringKey.verticalGlyphForm] = newValue
        }
    }

    public func alignment(_ alignment: NSTextAlignment) -> [NSAttributedStringKey: Any] {
        var result = self
        result.paragraphStyle = (paragraphStyle ?? NSParagraphStyle()).with {
            $0.alignment = alignment
        }
        return result
    }
}

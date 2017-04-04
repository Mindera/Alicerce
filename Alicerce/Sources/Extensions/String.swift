//
//  String.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 03/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

extension String {

    /// Returns the receiver casted to an `NSString`
    var nsString: NSString {
        return self as NSString
    }

    /// Returns a string object containing the characters of the receiver that lie within a given range.
    ///
    /// - Parameter nsRange: A range. The range must not exceed the bounds of the receiver.
    /// - Returns: A string object containing the characters of the receiver that lie within aRange.
    func substring(with nsRange: NSRange) -> String {
        return nsString.substring(with: nsRange) as String
    }
}

extension String {

    /// Attempts conversion of the receiver to a boolean value, according to the following rules:
    ///
    /// - true: `"true", "yes", "1"` (allowing case variations)
    /// - false: `"false", "no", "0"` (allowing case variations)
    ///
    /// If none of the following rules is verified, `nil` is returned.
    ///
    /// - returns: an optional boolean which will have the converted value, or `nil` if the conversion failed.
    func toBool() -> Bool? {
        switch self.lowercased() {
        case "true", "yes", "1": return true
        case "false", "no", "0": return false
        default: return nil
        }
    }
}

extension String {

    /// Returns a localized string using the receiver as the key.
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

//
//  Mappable.swift
//  Alicerce
//
//  Created by Luís Afonso on 06/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public protocol Mappable {

    /// Converts the object from a `Any` object to Itself.
    ///
    /// - Parameter object: 
    /// An object that information to fill the model. Usually a Dictionary.
    /// - Returns: 
    /// The object itself filled with values from the object
    /// - Throws: A MappableError
    static func model(from object: Any) throws -> Self

    /// Converts Itself into a `Any` object
    /// You can simply return `NSNull()` if it doesn't make sense in your context to do that.
    ///
    /// - Returns: An `Any`
    func json() -> Any
}

public extension Array where Element: Mappable {

    static func model(from object: [Any]) throws -> [Element] {
        return try object.map(Element.model(from:))
    }

    func json() -> [Any] {
        return map { $0.json() }
    }
}

public extension Mappable where Self: RawRepresentable {

    static func model(from object: Any) throws -> Self {
        guard let rawValue = object as? Self.RawValue else {
            throw JSON.Error.unexpectedType(expected: Self.RawValue.self, found: type(of: object))
        }

        guard let value = Self(rawValue: rawValue) else {
            throw JSON.Error.unexpectedRawValue(type: Self.self, found: rawValue)
        }

        return value
    }

    func json() -> Any {
        return rawValue
    }
}

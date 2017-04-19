//
//  Mappable.swift
//  Alicerce
//
//  Created by Luís Afonso on 06/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public enum MappableError: Error {

    case custom(String)

    /// Unwrapps the enum custom value
    var description: String {
        switch self {
        case let .custom(description): return description
        }
    }
}

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

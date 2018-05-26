//
//  JSON+Mappable.swift
//  Alicerce
//
//  Created by Luís Portela on 10/04/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import Foundation

extension JSON {

    // MARK: - Specified Type

    /// Parse an attribute of type `T: Mappable` with the given key on the given JSON dictionary, validating if
    /// the value can be used to instantiate a Mappable model. Additionally, an optional `parseAPIError`
    /// closure can be supplied
    /// so that if a parsing step fails an attempt is made to extract a domain specific error and throw it.
    ///
    /// - Parameters:
    ///   - type: The type of the attribute to parse.
    ///   - key: The JSON attribute key to parse.
    ///   - json: The JSON dictionary.
    ///   - parseAPIError: The API error parsing closure.
    /// - Returns: The value of type `T` associated to the given attribute's key.
    /// - Throws: An error of type `JSON.Error`, or a `Swift.Error` produced either by `parseAPIError`
    ///   or the parsing function.
    public static func parseMappableAttribute<T: Mappable>(
        _ type: T.Type,
        key: JSON.AttributeKey,
        json: JSON.Dictionary,
        where predicate: ParsePredicateClosure<T>? = nil,
        parseAPIError: ParseAPIErrorClosure? = nil) throws -> T {

        guard let anyValue = json[key] else {
            throw parseAPIError?(json) ?? Error.missingAttribute(key, json: json)
        }

        let any: Any = try parseValue(rawValue: anyValue,
                                      key: key,
                                      json: json,
                                      where: nil,
                                      parseAPIError: parseAPIError)

        let mappableObject: T = try T.model(from: any)

        guard predicate?(mappableObject) ?? true else {
            throw Error.unexpectedAttributeValue(key, json: json)
        }

        return mappableObject
    }

    /// Parse an ++optional++ attribute of type `T: Mappable` with the given key on the given JSON dictionary,
    /// validating if the raw value can be used to instantiate it. Additionally, an optional `parseAPIError` closure
    /// can be supplied so that if a parsing step fails an attempt is made to extract a domain specific error and throw
    /// it. If the key doesn't exist on the JSON, `nil` is returned unless an API error is parsed (and thrown),
    /// otherwise standard validations are made.
    ///
    /// - Parameters:
    ///   - type: The type of the attribute to parse.
    ///   - key: The JSON attribute key to parse.
    ///   - json: The JSON dictionary.
    ///   - parseAPIError: The API error parsing closure.
    /// - Returns: The value of type `T` associated to the given attribute's key.
    /// - Throws: An error of type `JSON.Error`, or a `Swift.Error` produced either by
    ///   `parseAPIError` or the parsing function.
    public static func parseOptionalMappableAttribute<T: Mappable>(
        _ type: T.Type,
        key: JSON.AttributeKey,
        json: JSON.Dictionary,
        where predicate: ParsePredicateClosure<T>? = nil,
        parseAPIError: ParseAPIErrorClosure? = nil) throws -> T? {

        guard let anyValue = json[key] else {
            if let apiError = parseAPIError?(json) { throw apiError }
            return nil
        }

        let any: Any = try parseValue(rawValue: anyValue,
                                      key: key,
                                      json: json,
                                      where: nil,
                                      parseAPIError: parseAPIError)

        let mappableObject: T = try T.model(from: any)

        guard predicate?(mappableObject) ?? true else {
            throw Error.unexpectedAttributeValue(key, json: json)
        }

        return mappableObject
    }

    // MARK: - Inferred Type

    /// Parse an attribute of type `T: Mappable` with the given key on the given JSON dictionary, validating if
    /// the raw value can be used to instantiate it. Additionally, an optional `parseAPIError` closure can be supplied
    /// so that if a parsing step fails an attempt is made to extract a domain specific error and throw it.
    ///
    /// - Parameters:
    ///   - type: The type of the attribute to parse.
    ///   - key: The JSON attribute key to parse.
    ///   - json: The JSON dictionary.
    ///   - parseAPIError: The API error parsing closure.
    /// - Returns: The value of type `T` associated to the given attribute's key.
    /// - Throws: An error of type `JSON.Error`, or a `Swift.Error` produced either by
    ///   `parseAPIError` or the parsing function.
    public static func parseMappableAttribute<T: Mappable>(
        _ key: JSON.AttributeKey,
        json: JSON.Dictionary,
        where predicate: ParsePredicateClosure<T>? = nil,
        parseAPIError: ParseAPIErrorClosure? = nil) throws -> T {
        return try parseMappableAttribute(T.self,
                                          key: key,
                                          json: json,
                                          where: predicate,
                                          parseAPIError: parseAPIError)
    }

    /// Parse an ++optional++ attribute of type `T: Mappable` with the given key on the given JSON dictionary,
    /// validating if the raw value can be used to instantiate it. Additionally, an optional `parseAPIError` closure
    /// can be supplied so that if a parsing step fails an attempt is made to extract a domain specific error and throw
    /// it. If the key doesn't exist on the JSON, `nil` is returned unless an API error is parsed (and thrown),
    /// otherwise standard validations are made.
    ///
    /// - Parameters:
    ///   - type: The type of the attribute to parse.
    ///   - key: The JSON attribute key to parse.
    ///   - json: The JSON dictionary.
    ///   - parseAPIError: The API error parsing closure.
    /// - Returns: The value of type `T` associated to the given attribute's key.
    /// - Throws: An error of type `JSON.Error`, or a `Swift.Error` produced either by `parseAPIError`
    ///   or the parsing function.
    public static func parseOptionalMappableAttribute<T: Mappable>(
        _ key: JSON.AttributeKey,
        json: JSON.Dictionary,
        where predicate: ParsePredicateClosure<T>? = nil,
        parseAPIError: ParseAPIErrorClosure? = nil) throws -> T? {
        return try parseOptionalMappableAttribute(T.self,
                                                  key: key,
                                                  json: json,
                                                  where: predicate,
                                                  parseAPIError: parseAPIError)
    }
}

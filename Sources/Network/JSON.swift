//
//  JSON.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 20/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

/// A case less enum to contain generic JSON parsing logic and namespace related types and errors.
public enum JSON {

    /// A JSON dictionary.
    public typealias Dictionary = [String : Any]

    /// A JSON array.
    public typealias Array = [Any]

    /// A JSON attribute key.
    public typealias AttributeKey = String

    /// A closure to parse a domain specific API error when a parsing step fails.
    public typealias ParseAPIErrorClosure = (JSON.Dictionary) -> Swift.Error?

    /// A predicate to validate a value after successfully being parsed.
    public typealias ParsePredicateClosure<T> = (T) -> Bool

    /// An Error occurred when parsing JSON.
    ///
    /// - serialization: serialization from data to JSON failed.
    /// - unexpectedType: unexpected type when casting the parsed raw JSON.
    /// - unexpectedAttributeType: unexpected type when casting a JSON attribute value.
    /// - unexpectedJSONAttributeValue: unexpected value when validating a JSON attribute's value with a predicate.
    /// - missingAttribute: missing attribute key in the JSON.
    public enum Error: Swift.Error {
        case serialization(Swift.Error)
        case unexpectedType(expected: Any.Type, found: Any.Type)
        case unexpectedAttributeType(JSON.AttributeKey, expected: Any.Type, found: Any.Type, json: JSON.Dictionary)
        case unexpectedAttributeValue(JSON.AttributeKey, json: JSON.Dictionary)
        case missingAttribute(JSON.AttributeKey, json: JSON.Dictionary)
    }

    // MARK: - Public methods

    /// Parse the given raw data into a JSON dictionary (`[String : Any]`).
    ///
    /// - Parameter data: The raw data to parse.
    /// - Returns: A parsed JSON dictionary.
    /// - Throws: An error of type `JSON.Error`.
    public static func parseDictionary(from data: Data) throws -> JSON.Dictionary {
        return try parse(from: data)
    }

    /// Parse the given raw data into a JSON array (`[Any]`).
    ///
    /// - Parameter data: The raw data to parse.
    /// - Returns: A parsed JSON array.
    /// - Throws: An error of type `JSON.Error`.
    public static func parseArray(from data: Data) throws -> JSON.Array {
        return try parse(from: data)
    }

    // MARK: - Specified Type

    /// Parse an attribute of type `T` with the given key on the given JSON dictionary, and optionally validate
    /// the value using a `where` predicate closure. Additionally, an optional `parseAPIError` closure can be supplied
    /// so that if a parsing step fails an attempt is made to extract a domain specific error and throw it.
    ///
    /// - Parameters:
    ///   - type: The type of the attribute to parse.
    ///   - key: The JSON attribute key to parse.
    ///   - json: The JSON dictionary.
    ///   - predicate: The validation predicate.
    ///   - parseAPIError: The API error parsing closure.
    /// - Returns: The value of type `T` associated to the given attribute's key.
    /// - Throws: An error of type `JSON.Error`, or a domain specific `Swift.Error` produced by `parseAPIError`.
    public static func parseAttribute<T>(_ type: T.Type,
                                         key: JSON.AttributeKey,
                                         json: JSON.Dictionary,
                                         where predicate: ParsePredicateClosure<T>? = nil,
                                         parseAPIError: ParseAPIErrorClosure? = nil) throws -> T {
        guard let rawValue = json[key] else {
            throw parseAPIError?(json) ?? Error.missingAttribute(key, json: json)
        }

        return try parseValue(rawValue: rawValue, key: key, json: json, where: predicate, parseAPIError: parseAPIError)
    }

    /// Parse an **optional** attribute of type `T` with the given key on the given JSON dictionary, and optionally
    /// validate the value using a `where` predicate closure. Additionally, an optional `parseAPIError` closure can be
    /// supplied so that if a parsing step fails an attempt is made to extract a domain specific error and throw it. If
    /// the key doesn't exist on the JSON, `nil` is returned unless an API error is parsed (and thrown), otherwise
    /// standard validations are made.
    ///
    /// - Parameters:
    ///   - type: The type of the attribute to parse.
    ///   - key: The JSON attribute key to parse.
    ///   - json: The JSON dictionary.
    ///   - predicate: The validation predicate.
    ///   - parseAPIError: The API error parsing closure.
    /// - Returns: The value of type `T` associated to the given attribute's key.
    /// - Throws: An error of type `JSON.Error`, or a domain specific `Swift.Error` produced by `parseAPIError`.
    public static func parseOptionalAttribute<T>(_ type: T.Type,
                                                 key: JSON.AttributeKey,
                                                 json: JSON.Dictionary,
                                                 where predicate: ParsePredicateClosure<T>? = nil,
                                                 parseAPIError: ParseAPIErrorClosure? = nil) throws -> T? {
        guard let rawValue = json[key] else {
            if let apiError = parseAPIError?(json) { throw apiError }
            return nil
        }

        return try parseValue(rawValue: rawValue, key: key, json: json, where: predicate, parseAPIError: parseAPIError)
    }

    // MARK: - Inferred Type

    /// Parse an attribute of type `T` with the given key on the given JSON dictionary, and optionally validate
    /// the value using a `where` predicate closure. Additionally, an optional `parseAPIError` closure can be supplied
    /// so that if a parsing step fails an attempt is made to extract a domain specific error and throw it.
    ///
    /// - Parameters:
    ///   - type: The type of the attribute to parse.
    ///   - key: The JSON attribute key to parse.
    ///   - json: The JSON dictionary.
    ///   - predicate: The validation predicate.
    ///   - parseAPIError: The API error parsing closure.
    /// - Returns: The value of type `T` associated to the given attribute's key.
    /// - Throws: An error of type `JSON.Error`, or a domain specific `Swift.Error` produced by `parseAPIError`.
    public static func parseAttribute<T>(key: JSON.AttributeKey,
                                         json: JSON.Dictionary,
                                         where predicate: ParsePredicateClosure<T>? = nil,
                                         parseAPIError: ParseAPIErrorClosure? = nil) throws -> T {
        return try parseAttribute(T.self, key: key, json: json, where: predicate, parseAPIError: parseAPIError)
    }

    /// Parse an **optional** attribute of type `T` with the given key on the given JSON dictionary, and optionally
    /// validate the value using a `where` predicate closure. Additionally, an optional `parseAPIError` closure can be
    /// supplied so that if a parsing step fails an attempt is made to extract a domain specific error and throw it. If
    /// the key doesn't exist on the JSON, `nil` is returned unless an API error is parsed (and thrown), otherwise
    /// standard validations are made.
    ///
    /// - Parameters:
    ///   - type: The type of the attribute to parse.
    ///   - key: The JSON attribute key to parse.
    ///   - json: The JSON dictionary.
    ///   - predicate: The validation predicate.
    ///   - parseAPIError: The API error parsing closure.
    /// - Returns: The value of type `T` associated to the given attribute's key.
    /// - Throws: An error of type `JSON.Error`, or a domain specific `Swift.Error` produced by `parseAPIError`.
    public static func parseOptionalAttribute<T>(key: JSON.AttributeKey,
                                                 json: JSON.Dictionary,
                                                 where predicate: ParsePredicateClosure<T>? = nil,
                                                 parseAPIError: ParseAPIErrorClosure? = nil) throws -> T? {
        return try parseOptionalAttribute(T.self, key: key, json: json, where: predicate, parseAPIError: parseAPIError)
    }

    // MARK: - Private methods

    /// Parse the given raw data into a type `T`.
    ///
    /// - Parameter data: The raw data to parse.
    /// - Returns: A parsed `T` instance.
    /// - Throws: An error of type `JSON.Error`.
    private static func parse<T>(from data: Data) throws -> T {
        let json: Any

        do {
            json = try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            throw Error.serialization(error)
        }

        guard let decoded = json as? T else {
            throw Error.unexpectedType(expected: T.self, found: type(of: json))
        }

        return decoded
    }

    /// Parse the given raw value into a type `T`.
    ///
    /// - Parameters:
    ///   - rawValue: The raw value.
    ///   - key: The JSON attribute key to which contained the value.
    ///   - json: The JSON dictionary.
    ///   - predicate: The validation predicate.
    ///   - parseAPIError: The API error parsing closure.
    /// - Returns: The value of type `T` associated to the given attribute's key.
    /// - Throws: An error of type `JSON.Error`, or a domain specific `Swift.Error` produced by `parseAPIError`.
    private static func parseValue<T>(rawValue: Any,
                                      key: JSON.AttributeKey,
                                      json: JSON.Dictionary,
                                      where predicate: ParsePredicateClosure<T>? = nil,
                                      parseAPIError: ParseAPIErrorClosure? = nil) throws -> T {
        guard let value = rawValue as? T else {
            throw parseAPIError?(json) ?? Error.unexpectedAttributeType(key,
                                                                        expected: T.self,
                                                                        found: type(of: rawValue),
                                                                        json: json)
        }

        guard predicate?(value) ?? true else {
            throw Error.unexpectedAttributeValue(key, json: json)
        }

        return value
    }
}

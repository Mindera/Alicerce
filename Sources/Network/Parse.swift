//
//  Parse.swift
//  Alicerce
//
//  Created by Luís Portela on 06/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

public enum Parse {

    public enum Error: Swift.Error {
        case json(Swift.Error)
        case image
        case noData
    }

    /// Converts raw data into a `T` object
    ///
    /// - Parameter data: Raw data
    /// - Returns: A `T` filled with values from the raw Data
    /// - Throws: 
    /// A Parse.Error that can be of type: 
    ///   - `serialization` if json serialization failed
    ///   - `mapping` if model mapping failed
    ///   - `other` an unknown error
    public static func json<T: Mappable>(data: Data) throws -> T {

        let json: Any

        do {
            json = try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            throw Error.json(JSON.Error.serialization(error))
        }

        do {
            return try T.model(from: json)
        } catch {
            throw Error.json(error)
        }
    }

    /// Converts raw data into an UIImage
    ///
    /// - Parameter data: Raw data
    /// - Returns: An UIImage from the raw data
    /// - Throws: A Parse.Error that can be of type:
    ///   - `serialization` if json serialization failed
    public static func image(data: Data) throws -> UIImage {

        guard let image = UIImage(data: data) else {
            throw Error.image
        }

        return image
    }

    /// Parses empty data
    ///
    /// - Parameter data: Raw data
    /// - Throws: A Parse.Error that can be of type
    public static func void(data: Data) throws {
        guard data.isEmpty else {
            throw Error.noData
        }
    }
}

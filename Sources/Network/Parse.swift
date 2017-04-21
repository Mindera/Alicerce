//
//  Parse.swift
//  Alicerce
//
//  Created by Luís Afonso on 06/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

public enum Parse {
    enum Error: Swift.Error {
        case json(Swift.Error)
        case image
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
}

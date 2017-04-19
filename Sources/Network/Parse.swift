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
        case serialization(String)
        case mapping(MappableError)
        case other(Swift.Error)
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
    static func json<T: Mappable>(data: Data) throws -> T {

        let decodedObject: T

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])

            decodedObject = try T.model(from: json)

        } catch let mappingError as MappableError {
            throw Error.mapping(mappingError)
        } catch let serializationError as NSError {
            throw Error.serialization(serializationError.localizedDescription)
        } catch {
            throw Error.other(error)
        }

        return decodedObject
    }

    /// Converts raw data into an UIImage
    ///
    /// - Parameter data: Raw data
    /// - Returns: An UIImage from the raw data
    /// - Throws: A Parse.Error that can be of type:
    ///   - `serialization` if json serialization failed
    static func image(data: Data) throws -> UIImage {

        guard let image = UIImage(data: data) else {
            throw Error.serialization("💥 Invalid image data! 😱")
        }

        return image
    }
}

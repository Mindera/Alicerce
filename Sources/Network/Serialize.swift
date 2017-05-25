//
//  Serialize.swift
//  Pods
//
//  Created by Luís Portela on 24/05/2017.
//
//

import Foundation

public protocol SerializeError: Swift.Error {}

public enum Serialize {

    enum Error: SerializeError {
        case imageDataInvalid(UIImage)
    }

    public static func imageAsPNGData(_ image: UIImage) throws-> Data {
        guard let imageData = UIImagePNGRepresentation(image) else {
            throw Error.imageDataInvalid(image)
        }

        return imageData
    }
}

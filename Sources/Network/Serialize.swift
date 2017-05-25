//
//  Serialize.swift
//  Alicerce
//
//  Created by Luís Portela on 24/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public protocol SerializeError: Swift.Error {}

public enum Serialize {

    enum Error: SerializeError {
        case invalidImage(UIImage)
    }

    public static func imageAsPNGData(_ image: UIImage) throws-> Data {
        guard let imageData = UIImagePNGRepresentation(image) else {
            throw Error.invalidImage(image)
        }

        return imageData
    }
}

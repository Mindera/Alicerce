import Foundation

public enum Serialize {

    enum Error: Swift.Error {
        case json(Swift.Error)
        case invalidImage(UIImage)
    }


    /// Converts a Mappable `T` object into raw data
    ///
    /// - Parameter object: A Mappable object that is converted into a dictionary
    /// - Returns: Raw data representation of the object
    /// - Throws:
    /// A Serialize.Error that can be of type:
    ///   - `serialization` if json serialization failed
    public static func json<T: Mappable>(object: T) throws -> Data {

        let json = object.json()

        do {
            return try JSONSerialization.data(withJSONObject: json, options: [])
        } catch {
            throw Error.json(JSON.Error.serialization(error))
        }
    }


    /// Converts a PNG image into raw data
    ///
    /// - Parameter image: A PNG image as UIImage
    /// - Returns: A Raw data representation of a PNG image
    /// - Throws:
    /// A Serialize.Error that can be of type:
    ///   - `invalidImage` if the image isn't a PNG
    public static func imageAsPNGData(_ image: UIImage) throws-> Data {
        guard let imageData = UIImagePNGRepresentation(image) else {
            throw Error.invalidImage(image)
        }

        return imageData
    }
}

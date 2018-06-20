import Foundation

public enum Persistence {

    public typealias Key = String

    public enum Error: Swift.Error {
        case noObjectForKey
        case other(Swift.Error)
    }
}


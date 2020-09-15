import Foundation

public enum FetchAndDecodeError: Error {
    case fetch(Error)
    case decode(Error)
}

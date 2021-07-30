import Foundation

/// A type representing something that can be routed (via a URL).
public protocol Routable {

    var route: URL { get }
}

extension URL: Routable {

    public var route: URL { self }
}

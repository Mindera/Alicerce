import Foundation

/// A type representing a URL router.
public protocol Router {

    /// A router's custom payload type to be passed when a route is routed.
    associatedtype T

    /// Routes the given route, and optionally notifies routing success with a custom payload.
    ///
    /// - Parameters:
    ///   - route: The route to route.
    ///   - handleCompletion: The closure to notify routing success with custom payload.
    /// - Throws: An error if the route couldn't be routed.
    func route(_ route: URL, handleCompletion: ((T) -> Void)?) throws
}

/// A type that handles URL routes form a router.
public protocol RouteHandler {

    /// A handler's custom payload type to be passed when a route is handled.
    associatedtype T

    /// Handles a route that has been matched by the router, and optionally notifies handle completion.
    ///
    /// When the router matches a given route, it invokes this method on the the corresponding handler with the matched
    /// route, any detected parameters and query items.
    ///
    /// If defined, the given `completion` closure should be invoked with the handler's custom payload on handle
    /// completion.
    ///
    /// - Parameters:
    ///   - route: The route to handle.
    ///   - parameters: The parameters captured by the router.
    ///   - queryItems: The query items contained in the route.
    ///   - completion: The closure to notify handle completion with custom payload.
    func handle(route: URL, parameters: Route.Parameters, queryItems: [URLQueryItem], completion: ((T) -> Void)?)
}

/// A type-erased URL route handler.
public final class AnyRouteHandler<T>: RouteHandler {

    /// The type-erased handler's wrapped instance `handle` method, stored as a closure.
    private let _handle: (URL, Route.Parameters, [URLQueryItem], ((T) -> Void)?) -> Void

    /// The type-erased tracker's wrapped instance.
    private let _wrapped: Any

    /// Creates a type-erased instance of a route handler that wraps the given instance.
    ///
    /// - Parameters:
    ///   - handler: The route handler instance to wrap.
    public init<H: RouteHandler>(_ handler: H) where H.T == T {

        _handle = handler.handle
        _wrapped = handler
    }

    /// Handles a route that has been matched by the router, and optionally notifies handle completion via the wrapped
    /// instance.
    ///
    /// When the router matches a given route, it invokes this method on the the corresponding handler with the matched
    /// route, any detected parameters and query items.
    ///
    /// If defined, the given `completion` closure should be invoked with the handler's custom payload on handle
    /// completion.
    ///
    /// - Parameters:
    ///   - route: The route to handle.
    ///   - parameters: The parameters captured by the router.
    ///   - queryItems: The query items contained in the route.
    ///   - completion: The closure to notify handle completion with custom payload.
    public func handle(
        route: URL,
        parameters: Route.Parameters,
        queryItems: [URLQueryItem],
        completion: ((T) -> Void)?
    ) {

        _handle(route, parameters, queryItems, completion)
    }
}

extension AnyRouteHandler: CustomStringConvertible {

    public var description: String { return "\(type(of: self))(\(_wrapped))" }
}

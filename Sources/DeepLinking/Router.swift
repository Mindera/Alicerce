//
//  Router.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 10/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

public protocol RouteHandler {
    associatedtype T

    func handle(route: URL, parameters: [String : String], queryItems: [URLQueryItem], completion: ((T) -> Void)?)
}

public final class AnyRouteHandler<T>: RouteHandler {

    let _handle: (URL, [String : String], [URLQueryItem], ((T) -> Void)?) -> Void

    init<H: RouteHandler>(_ h: H) where H.T == T {
        _handle = h.handle
    }

    public func handle(route: URL,
                       parameters: [String : String],
                       queryItems: [URLQueryItem],
                       completion: ((T) -> Void)?) {
        _handle(route, parameters, queryItems, completion)
    }
}

public protocol Router {
    associatedtype T

    func route(_ route: URL, handleCompletion: ((T) -> Void)?) throws
}

public enum TreeRouterError: Swift.Error {
    case invalidRoute(InvalidRouteError)
    case duplicateRoute
    case routeNotFound
    case handlerTypeMismatch(expected: Any.Type, found: Any.Type)

    public enum InvalidRouteError: Swift.Error {
        case misplacedEmptyComponent
        case conflictingVariableComponent(existing: String, new: String)
        case invalidVariableComponent(String)
        case invalidURL
        case unexpected(Swift.Error)
    }
}

public final class TreeRouter<T>: Router {

    public typealias Match = Route.Tree<AnyRouteHandler<T>>.Match

    private typealias Tree = Route.Tree<AnyRouteHandler<T>>
    private typealias AnnotatedParsedRoute = (scheme: Route.Scheme, components: [Route.Component])
    private typealias ParsedRoute = (scheme: Route.Scheme, components: [Route.Component], queryItems: [URLQueryItem])

    private var routes: Atomic<[Route.Scheme : Tree]> = Atomic([:])

    public func register(_ route: URL, handler: AnyRouteHandler<T>) throws {
        let (scheme, routeComponents) = parseAnnotatedRoute(route)

        try routes.modify { routes in
            do {
                if var schemeTree = routes[scheme] {
                    try schemeTree.add(route: routeComponents, handler: handler)
                    routes[scheme] = schemeTree
                } else {
                    routes[scheme] = try Tree(route: routeComponents, handler: handler)
                }
            } catch Route.TreeError.duplicateEmptyComponent {
                throw TreeRouterError.duplicateRoute
            } catch Route.TreeError.invalidRoute {
                // empty route elements are only allowed at the end of the route
                throw TreeRouterError.invalidRoute(.misplacedEmptyComponent)
            } catch let Route.TreeError.conflictingParameterName(existing, new) {
                throw TreeRouterError.invalidRoute(.conflictingVariableComponent(existing: existing, new: new))
            } catch {
                throw TreeRouterError.invalidRoute(.unexpected(error))
            }
        }
    }

    @discardableResult
    public func unregister(_ route: URL) throws -> AnyRouteHandler<T> {
        let (scheme, routeComponents) = parseAnnotatedRoute(route)

        return try routes.modify { routes in
            guard var schemeTree = routes[scheme] else { throw TreeRouterError.routeNotFound }

            let handler: AnyRouteHandler<T>

            do {
                handler = try schemeTree.remove(route: routeComponents)
            } catch Route.TreeError.routeNotFound {
                throw TreeRouterError.routeNotFound
            } catch {
                assertionFailure("🔥: unexpected error when unregistering \(route)! Error: \(error)")
                throw TreeRouterError.routeNotFound
            }

            routes[scheme] = schemeTree

            return handler
        }
    }

    public func route(_ route: URL, handleCompletion: ((T) -> Void)? = nil) throws {
        let (scheme, routeComponents, queryItems) = try parseRoute(route)

        let match: Match = try routes.modify { routes in
            guard let schemeTree = routes[scheme] else { throw TreeRouterError.routeNotFound }

            do {
                return try schemeTree.match(route: routeComponents)
            } catch Route.TreeError.routeNotFound {
                throw TreeRouterError.routeNotFound
            } catch let Route.TreeError.invalidComponent(component) {
                throw TreeRouterError.invalidRoute(.invalidVariableComponent(component.description))
            } catch {
                assertionFailure("🔥: unexpected error when routing \(route)! Error: \(error)")
                throw TreeRouterError.invalidRoute(.unexpected(error))
            }
        }

        match.handler.handle(route: route,
                             parameters: match.parameters,
                             queryItems: queryItems,
                             completion: handleCompletion)
    }

    // MARK: - Private methods

    private func parseAnnotatedRoute(_ route: URL, appendEmpty: Bool = true) -> AnnotatedParsedRoute {
        let scheme = route.scheme ?? ""

        // use a wildcard for empty hosts, since we can't use an .empty component unless it's terminating a route
        // TODO: evaluate if we should use a dummy value here too, e.g. "|empty|" (which crashes URL and URLComponent)
        let hostComponent = Route.Component(component: route.host ?? "*")
        let pathComponents = route.pathComponents.filter { $0 != "/" }.map(Route.Component.init(component:))

        assert(route.query == nil, "🔥: URL query items are ignored when registering/unregistering routes!")

        return (scheme: scheme, components: [hostComponent] + pathComponents)
    }

    private func parseRoute(_ route: URL, appendEmpty: Bool = true) throws -> ParsedRoute {
        let scheme = route.scheme ?? ""

        // use a dummy value for empty hosts, since we can't use an .empty component unless it's terminating a route
        // and it will match registered wildcard routes (empty routes). "|empty|" should be safe since it crashes URL 
        // and URLComponents creation, which should avoid collisions
        let hostComponent = Route.Component(component: route.host ?? "|empty|")
        var pathComponents = route.pathComponents.filter { $0 != "/" }.map(Route.Component.init(component:))

        // add an empty path component if not already on the last position (to match leafs and empty nodes)
        if pathComponents.last != .empty {
            pathComponents.append(.empty)
        }

        let routeComponents = [hostComponent] + pathComponents

        guard let urlComponents = URLComponents(url: route, resolvingAgainstBaseURL: false) else {
            throw TreeRouterError.invalidRoute(.invalidURL)
        }

        return (scheme: scheme, components: routeComponents, queryItems: urlComponents.queryItems ?? [])
    }
}

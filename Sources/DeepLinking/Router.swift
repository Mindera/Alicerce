//
//  Router.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 10/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

public protocol RouteHandler {
    func handle(route: URL, parameters: [String : String], queryItems: [URLQueryItem])
}

public protocol Router {
    associatedtype Handler: RouteHandler

    func register(_ route: URL, handler: Handler) throws
    func unregister(_ route: URL) throws -> Handler

    func route(_ route: URL) throws
}

public final class TreeRouter<Handler: RouteHandler>: Router {

    public typealias Match = Route.Tree<Handler>.Match

    private typealias Tree = Route.Tree<Handler>
    private typealias AnnotatedParsedRoute = (scheme: Route.Scheme, components: [Route.Component])
    private typealias ParsedRoute = (scheme: Route.Scheme, components: [Route.Component], queryItems: [URLQueryItem])

    public enum Error: Swift.Error {
        case invalidRoute(InvalidRouteError)
        case duplicateRoute
        case routeNotFound

        public enum InvalidRouteError: Swift.Error {
            case misplacedEmptyComponent
            case conflictingVariableComponent(existing: String, new: String)
            case invalidVariableComponent(String)
            case invalidURL
            case unexpected(Swift.Error)
        }
    }

    private var routes: [Route.Scheme : Tree] = [:]
    private let queue: DispatchQueue

    public init(qos: DispatchQoS = .default) {
        queue = DispatchQueue(label: "com.mindera.Alicerce.\(type(of: self)).queue", qos: qos)
    }

    public func register(_ route: URL, handler: Handler) throws {
        let (scheme, routeComponents) = parseAnnotatedRoute(route)

        try queue.sync { [unowned self] in

            do {
                if var schemeTree = self.routes[scheme] {
                    try schemeTree.add(route: routeComponents, handler: handler)
                    self.routes[scheme] = schemeTree
                } else {
                    self.routes[scheme] = try Tree(route: routeComponents, handler: handler)
                }
            } catch Tree.Error.duplicateEmptyComponent {
                throw Error.duplicateRoute 
            } catch Tree.Error.invalidRoute {
                 // empty route elements are only allowed at the end of the route
                throw Error.invalidRoute(.misplacedEmptyComponent)
            } catch let Tree.Error.conflictingParameterName(existing, new) {
                throw Error.invalidRoute(.conflictingVariableComponent(existing: existing, new: new))
            } catch {
                throw Error.invalidRoute(.unexpected(error))
            }
        }
    }

    public func unregister(_ route: URL) throws -> Handler {
        let (scheme, routeComponents) = parseAnnotatedRoute(route)

        return try queue.sync { [unowned self] in
            guard var schemeTree = self.routes[scheme] else { throw Error.routeNotFound }

            let handler: Handler

            do {
                handler = try schemeTree.remove(route: routeComponents)
            } catch Tree.Error.routeNotFound {
                throw Error.routeNotFound
            } catch {
                assertionFailure("🔥: unexpected Route.Tree.Error type!")
                // FIXME: add logging
                print("⚠️: unexpected error when unregistering \(route)! Error: \(error)")
                throw Error.routeNotFound
            }

            self.routes[scheme] = schemeTree

            return handler
        }
    }

    public func route(_ route: URL) throws {
        let (scheme, routeComponents, queryItems) = try parseRoute(route)

        let match: Match = try queue.sync { [unowned self] in
            guard let schemeTree = self.routes[scheme] else { throw Error.routeNotFound }

            do {
                return try schemeTree.match(route: routeComponents)
            } catch Tree.Error.routeNotFound {
                throw Error.routeNotFound
            } catch let Tree.Error.invalidComponent(component) {
                throw Error.invalidRoute(.invalidVariableComponent(component.description))
            } catch {
                assertionFailure("🔥: unexpected Route.Tree.Error type!")
                // FIXME: add logging
                print("⚠️: unexpected error when routing \(route)! Error: \(error)")
                throw Error.invalidRoute(.unexpected(error))
            }
        }

        match.handler.handle(route: route, parameters: match.parameters, queryItems: queryItems)
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
        //and URLComponents creation, which should avoid collisions
        let hostComponent = Route.Component(component: route.host ?? "|empty|") // this should be
        var pathComponents = route.pathComponents.filter { $0 != "/" }.map(Route.Component.init(component:))

        // add an empty path component if not already on the last position (to match leafs and empty nodes)
        if pathComponents.last != .empty {
            pathComponents.append(.empty)
        }

        let routeComponents = [hostComponent] + pathComponents

        guard let urlComponents = URLComponents(url: route, resolvingAgainstBaseURL: false) else {
            throw Error.invalidRoute(.invalidURL)
        }

        return (scheme: scheme, components: routeComponents, queryItems: urlComponents.queryItems ?? [])
    }
}

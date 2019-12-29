import Foundation

extension Route {

    /// An error produced by `TrieRouter` instances.
    public enum TrieRouterError: Error {

        /// The route already exists.
        case duplicateRoute

        /// The route is invalid.
        case invalidRoute(InvalidRouteError)

        /// The route conflicts with an existing route.
        case conflictingRoute(ConflictingRouteError)

        // The route can't been found.
        case routeNotFound

        /// An error detailing an invalid route.
        public enum InvalidRouteError: Error {

            /// A duplicate parameter name was detected in the route.
            case duplicateParameterName(String)

            /// The route contains a catchAll component in an invalid position (must be the last in the route).
            case misplacedCatchAllComponent(String?)

            // The route is not a valid URL.
            case invalidURL

            /// An unexpected error has occured.
            case unexpected(Error)
        }

        // An error detailing a conflict between a route and existing routes.
        public enum ConflictingRouteError: Error {

            /// A route already exists in the router containing a parameter at the same position, with a different name.
            case parameterComponent(existing: String, new: String)

            /// A route already exists in the router containing a catchAll at the same position, with a different name.
            case catchAllComponent(existing: String?, new: String?)
        }
    }

    /// A URL router that is backed by a **trie** tree and forwards route handling to registered handlers.
    ///
    /// Routes are registered with an associated handler, which on match handles the event and optionally invokes a
    /// completion closure with an abitrary payload of type `T`. This allows handlers to perform asynchronous work even
    /// though route matching is made synchronously.
    ///
    /// - Remark: Access to the backing trie tree data structure *is* synchronized, so all operations can safely be
    /// called from different threads.
    ///
    /// - Note: https://en.wikipedia.org/wiki/Trie for more information.
    public final class TrieRouter<T>: Router {

        /// A type representing the router's trie tree node.
        fileprivate typealias TrieNode = Route.TrieNode<AnyRouteHandler<T>>

        /// A type representing a route to match.
        private typealias MatchRoute = (components: [String], queryItems : [URLQueryItem])

        /// A type representing a matched route,.
        private typealias Match = (parameters: Route.Parameters, handler: AnyRouteHandler<T>)

        /// The router's trie tree.
        fileprivate var trie: Atomic<TrieNode> = Atomic(TrieNode())

        /// Creates an instance of a trie router.
        public init() {}

        /// Registers a new route in the router with the given handler.
        ///
        /// - Parameters:
        ///   - route: The route to register.
        ///   - handler: The handler to associate with the route and handle it on match.
        /// - Throws: A `TrieRouterError` error if the route is invalid or a conflict exists.
        public func register(_ route: URL, handler: AnyRouteHandler<T>) throws {

            let routeComponents = parseAnnotatedRoute(route)

            try trie.modify { node in

                do {
                    try node.add(routeComponents, handler: handler)
                } catch Route.TrieNodeError.conflictingNodeHandler {
                    throw TrieRouterError.duplicateRoute
                } catch Route.TrieNodeError.duplicateParameterName(let parameterName) {
                    throw TrieRouterError.invalidRoute(.duplicateParameterName(parameterName))
                } catch Route.TrieNodeError.conflictingParameterName(let existing, let new) {
                    throw TrieRouterError.conflictingRoute(.parameterComponent(existing: existing, new: new))
                } catch Route.TrieNodeError.conflictingCatchAllComponent(let existing, let new) {
                    throw TrieRouterError.conflictingRoute(.catchAllComponent(existing: existing, new: new))
                } catch Route.TrieNodeError.misplacedCatchAllComponent(let catchAllName) {
                    throw TrieRouterError.invalidRoute(.misplacedCatchAllComponent(catchAllName))
                } catch {
                    assertionFailure("🔥 Unexpected error when registering \(route)! Error: \(error)")
                    throw TrieRouterError.invalidRoute(.unexpected(error))
                }
            }
        }

        /// Unregisters the given route from the router, and returns the associated handler if found.
        ///
        /// - Parameter route: The route to unregister
        /// - Throws: A `TrieRouterError` error if the route is invalid or wasn't found.
        @discardableResult
        public func unregister(_ route: URL) throws -> AnyRouteHandler<T> {

            let routeComponents = parseAnnotatedRoute(route)

            return try trie.modify { node in

                do {
                    return try node.remove(routeComponents)
                } catch Route.TrieNodeError.routeNotFound {
                    throw TrieRouterError.routeNotFound
                } catch Route.TrieNodeError.misplacedCatchAllComponent(let catchAllName) {
                    throw TrieRouterError.invalidRoute(.misplacedCatchAllComponent(catchAllName))
                } catch {
                    assertionFailure("🔥 Unexpected error when unregistering \(route)! Error: \(error)")
                    throw TrieRouterError.routeNotFound
                }
            }
        }

        /// Routes the given route by matching it against the current trie, and optionally notifies routing success
        /// with a custom payload from the route handler.
        ///
        /// - Parameters:
        ///   - route: The route to route.
        ///   - handleCompletion: The closure to notify routing success with custom payload from the route handler.
        /// - Throws: A `TrieRouterError` error if the route wasn't found.
        public func route(_ route: URL, handleCompletion: ((T) -> Void)? = nil) throws {

            let (pathComponents, queryItems) = try parseMatchRoute(route)

            let match: Match = try trie.withValue { node in

                var parameters: Route.Parameters = [:]

                guard let handler = node.match(pathComponents, parameters: &parameters) else {
                    throw TrieRouterError.routeNotFound
                }

                return (parameters: parameters, handler: handler)
            }

            match.handler.handle(
                route: route,
                parameters: match.parameters,
                queryItems: queryItems,
                completion: handleCompletion
            )
        }

        // MARK: - Private methods

        /// Parses the given *annotated* route into an array of type safe route components, to be registered or
        /// unregistered.
        ///
        /// Annotated routes contain additional information that allow matching routes as:
        ///
        /// - constant values (`value`)
        /// - arbitrary parameters (`:variable`)
        /// - any value (wildcard, `*`)
        /// - any remaining route (catchAll, `**` or `**variable`)
        ///
        /// - Parameter route: The annotated route to parsed.
        private func parseAnnotatedRoute(_ route: URL) -> [Route.Component] {

            // use a wildcard for empty schemes/hosts, to match any scheme/host
            let schemeComponent = route.scheme.constantOrWildcardComponent
            let hostComponent = route.host.constantOrWildcardComponent
            let pathComponents = route.pathComponents.filter { $0 != "/" }.map(Route.Component.init(component:))

            assert(route.query == nil, "🔥 URL query items are ignored when registering/unregistering routes!")

            return [schemeComponent, hostComponent] + pathComponents
        }

        /// Parses the given route into an array of route components and query items to be matched by the router and
        /// forwarded to the handler on success, respectively.
        ///
        /// - Parameter route: The route to be parsed.
        /// - Throws: A `TrieRouterError` error if the URL is invalid.
        private func parseMatchRoute(_ route: URL) throws -> MatchRoute {

            // use an empty string for empty scheme/host, to match wildcard scheme/host
            let schemeComponent = route.scheme ?? ""
            let hostComponent = route.host ?? ""
            let pathComponents = route.pathComponents.filter { $0 != "/" }

            let routeComponents = [schemeComponent, hostComponent] + pathComponents

            guard let urlComponents = URLComponents(url: route, resolvingAgainstBaseURL: false) else {
                throw TrieRouterError.invalidRoute(.invalidURL)
            }

            return (components: routeComponents, queryItems: urlComponents.queryItems ?? [])
        }
    }
}

// MARK: - CustomStringConvertible

extension Route.TrieRouter: CustomStringConvertible {

    public var description: String { return trie.value.description }
}

// MARK: - Helpers

private extension Optional where Wrapped == String {

    /// A `.constant` route component if not `nil` nor empty (`""`), `.wildcard` otherwise.
    var constantOrWildcardComponent: Route.Component {

        guard let value = self, value != "" else { return .wildcard }

        return .constant(value)
    }
}

@available(*, unavailable, renamed: "Route.TrieRouter")
public typealias TreeRouter<Handler> = Route.TrieRouter<Handler>

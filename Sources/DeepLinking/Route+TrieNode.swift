import Foundation

// partially inpired by https://github.com/vapor/routing-kit 🙏

extension Route {

    /// An error produced by `TrieNode` instances.
    public enum TrieNodeError: Error {

        /// An attempt was made to associate a handler to a node which already contains one.
        case conflictingNodeHandler

        /// A duplicate parameter name was detected in the route.
        case duplicateParameterName(String)

        /// A parameter child already exists in the node with a different name.
        case conflictingParameterName(existing: String, new: String)

        /// A catchAll child already exists in the node, with a different name.
        case conflictingCatchAllComponent(existing: String?, new: String?)

        /// The route contains a catchAll component in an invalid position (must be the last in the route).
        case misplacedCatchAllComponent(String?)

        /// The route was not found in the node (and children).
        case routeNotFound
    }

    /// A node of a Trie tree of routes.
    public final class TrieNode<Handler> {

        /// A parameter child node.
        public struct Parameter {

            /// The parameter's name.
            let name: String

            /// The parameter's child node.
            let node: TrieNode
        }

        /// A catchAll child node.
        public struct CatchAll {

            /// The catchAll's name.
            let name: String?

            /// The catchAll's handler (can't have child nodes).
            let handler: Handler
        }

        /// The node's constant child nodes.
        private(set) var constants: [String: TrieNode]

        /// The node's parameter child node.
        private(set) var parameter: Parameter?

        /// The node's wildcard chil node.
        private(set) var wildcard: TrieNode?

        /// The node's catchAll child node.
        private(set) var catchAll: CatchAll?

        /// The node's handler.
        private(set) var handler: Handler?

        /// A Boolean value that indicates whether the node is empty.
        public var isEmpty: Bool {
            return constants.isEmpty && parameter == nil && wildcard == nil && catchAll == nil && handler == nil
        }

        // MARK: - Initialization

        /// Creates an instance of a node from the given child nodes and handler.
        ///
        /// - Parameters:
        ///   - constants: The node's constant child nodes.
        ///   - parameter: The node's parameter child node.
        ///   - wildcard: The node's wildcard child node.
        ///   - catchAll: The node's catchAll child node.
        ///   - handler: The node's handler.
        public init(
            constants: [String: TrieNode] = [:],
            parameter: Parameter? = nil,
            wildcard: TrieNode? = nil,
            catchAll: CatchAll? = nil,
            handler: Handler? = nil
        ) {

            self.constants = constants
            self.parameter = parameter
            self.wildcard = wildcard
            self.catchAll = catchAll
            self.handler = handler
        }

        /// Creates an instance of a node from the given route and handler.
        ///
        /// - Parameters:
        ///   - route: The route to build the node from.
        ///   - handler: The handler to associate with the resulting leaf node.
        /// - Throws: A `TrieNodeError` error if the route is invalid or a conflict exists.
        public convenience init(route: [Route.Component], handler: Handler) throws {

            var parameters = Set<String>()

            try self.init(route: route, handler: handler, parameters: &parameters)
        }

        /// Creates an instance of a node _recursively_ from the given route and handler, checking for duplicate
        /// parameter names.
        ///
        /// - Parameters:
        ///   - route: The route to build the node from.
        ///   - handler: The handler to associate with the resulting leaf node.
        ///   - parameters: A set containing all parameter names in the original route until the current node.
        /// - Throws: A `TrieNodeError` error if the route is invalid or a conflict exists.
        private convenience init(route: [Route.Component], handler: Handler, parameters: inout Set<String>) throws {

            let remainingRoute = Array(route.dropFirst())

            switch route.first {
            case nil:
                self.init(handler: handler)

            case .constant(let name)?:
                self.init(
                    constants: [name: try TrieNode(route: remainingRoute, handler: handler, parameters: &parameters)]
                )

            case .parameter(let name)?:
                guard parameters.contains(name) == false else { throw TrieNodeError.duplicateParameterName(name) }
                parameters.insert(name)

                self.init(
                    parameter: Parameter(
                        name: name,
                        node: try TrieNode(route: remainingRoute, handler: handler, parameters: &parameters)
                    )
                )

            case .wildcard?:
                self.init(wildcard: try TrieNode(route: remainingRoute, handler: handler, parameters: &parameters))

            case .catchAll(let name)?:
                // catchAll component should be the last
                guard route.count == 1 else { throw TrieNodeError.misplacedCatchAllComponent(name) }

                if let name = name, parameters.contains(name) { throw TrieNodeError.duplicateParameterName(name) }

                self.init(catchAll: CatchAll(name: name, handler: handler))
            }
        }

        // MARK: - Public methods

        /// Adds a new route to the node with the given handler.
        ///
        /// - Parameters:
        ///   - route: The route to add to the node.
        ///   - handler: The handler to associate with the resulting leaf node.
        /// - Throws: A `TrieNodeError` error if the route is invalid or a conflict exists.
        public func add(_ route: [Route.Component], handler: Handler) throws {

            var parameters = Set<String>()

            try _add(route, handler: handler, parameters: &parameters)
        }

        /// Removes a route from the node, and returns the associated handler if found.
        ///
        /// - Parameter route: The route to add to the node.
        /// - Throws: A `TrieNodeError` error if the route is invalid or doesn't exist.
        public func remove(_ route: [Route.Component]) throws -> Handler {

            let remainingRoute = Array(route.dropFirst())

            switch route.first {
            case nil:
                guard let handler = handler else { throw TrieNodeError.routeNotFound }

                self.handler = nil
                return handler

            case .constant(let name)?:
                guard let childNode = constants[name] else { throw TrieNodeError.routeNotFound }

                let handler = try childNode.remove(remainingRoute)
                if childNode.isEmpty { constants[name] = nil }
                return handler

            case .parameter(let name)?:
                guard let existingParameter = parameter, existingParameter.name == name else {
                    throw TrieNodeError.routeNotFound
                }

                let handler = try existingParameter.node.remove(remainingRoute)
                if existingParameter.node.isEmpty { parameter = nil }
                return handler

            case .wildcard?:
                guard let childNode = wildcard else { throw TrieNodeError.routeNotFound }

                let handler = try childNode.remove(remainingRoute)
                if childNode.isEmpty { wildcard = nil }
                return handler

            case .catchAll(let name)?:
                // catchAll component should be the last
                guard route.count == 1 else { throw TrieNodeError.misplacedCatchAllComponent(name) }

                guard let existingCatchAll = catchAll, existingCatchAll.name == name else {
                    throw TrieNodeError.routeNotFound
                }

                catchAll = nil
                return existingCatchAll.handler
            }
        }

        /// Matches a given route _recursively_ against the node, and returns the corresponding handler if found.
        ///
        /// - Parameters:
        ///   - route: The route to match against the node.
        ///   - parameters: A dictionary containing all parameters and respective values matched by the route.
        public func match(_ route: [String], parameters: inout Route.Parameters) -> Handler? {

            let remainingRoute = Array(route.dropFirst())

            switch route.first {
            case nil:
                return handler

            case let value?:
                if let handler = constants[value]?.match(remainingRoute, parameters: &parameters) { return handler }

                if let existingParameter = parameter,
                    let handler = existingParameter.node.match(remainingRoute, parameters: &parameters) {

                    parameters[existingParameter.name] = value

                    return handler
                }

                if let childNode = wildcard, let handler = childNode.match(remainingRoute, parameters: &parameters) {
                    return handler
                }

                if let existingCatchAll = catchAll {

                    if let catchAllParameterName = existingCatchAll.name {
                        parameters[catchAllParameterName] = route.joined(separator: "/")
                    }

                    return existingCatchAll.handler
                }

                return nil
            }
        }

        // MARK: - Private methods

        /// Adds a new route to the node _recursively_ with the given handler, checking for duplicate parameter names.
        ///
        /// - Parameters:
        ///   - route: The route to add to the node.
        ///   - handler: The handler to associate with the resulting leaf node.
        ///   - parameters: A set containing all parameter names in the original route until the current node.
        private func _add(_ route: [Route.Component], handler: Handler, parameters: inout Set<String>) throws {

            let remainingRoute = Array(route.dropFirst())

            switch route.first {
            case nil:
                // we could possibly support handler overwriting behavior
                guard self.handler == nil else { throw TrieNodeError.conflictingNodeHandler }
                self.handler = handler

            case .constant(let name)?:
                guard let node = constants[name] else {
                    constants[name] = try TrieNode(route: remainingRoute, handler: handler, parameters: &parameters)
                    return
                }

                try node._add(remainingRoute, handler: handler, parameters: &parameters)

            case .parameter(let newParameterName)?:
                guard parameters.contains(newParameterName) == false else {
                    throw TrieNodeError.duplicateParameterName(newParameterName)
                }
                parameters.insert(newParameterName)

                guard let existingParameter = parameter else {
                    parameter = Parameter(
                        name: newParameterName,
                        node: try TrieNode(route: remainingRoute, handler: handler, parameters: &parameters)
                    )
                    return
                }

                guard existingParameter.name == newParameterName else {
                    throw TrieNodeError.conflictingParameterName(
                        existing: existingParameter.name,
                        new: newParameterName
                    )
                }

                try existingParameter.node._add(remainingRoute, handler: handler, parameters: &parameters)

            case .wildcard?:
                guard let childNode = wildcard else {
                    wildcard = try TrieNode(route: remainingRoute, handler: handler, parameters: &parameters)
                    return
                }

                try childNode._add(remainingRoute, handler: handler, parameters: &parameters)

            case .catchAll(let newCatchAllName)?:
                // catchAll component should be the last
                guard route.count == 1 else { throw TrieNodeError.misplacedCatchAllComponent(newCatchAllName) }

                if let newCatchAllName = newCatchAllName, parameters.contains(newCatchAllName) {
                    throw TrieNodeError.duplicateParameterName(newCatchAllName)
                }

                if let existingCatchAll = catchAll {
                    throw TrieNodeError.conflictingCatchAllComponent(
                        existing: existingCatchAll.name,
                        new: newCatchAllName
                    )
                }

                catchAll = CatchAll(name: newCatchAllName, handler: handler)
            }
        }
    }
}

// MARK: - Equatable

extension Route.TrieNode.Parameter: Equatable where Handler: Equatable {}

extension Route.TrieNode.CatchAll: Equatable where Handler: Equatable {}

extension Route.TrieNode: Equatable where Handler: Equatable {

    public static func == (lhs: Route.TrieNode<Handler>, rhs: Route.TrieNode<Handler>) -> Bool {

        return lhs.constants == rhs.constants
            && lhs.parameter == rhs.parameter
            && lhs.wildcard == rhs.wildcard
            && lhs.catchAll == rhs.catchAll
            && lhs.handler == rhs.handler
    }
}

// MARK: - CustomStringConvertible

extension Route.TrieNode: CustomStringConvertible {

    public var description: String {

        var components: [(name: String, child: String?)] = []

        for (name, node) in constants { components.append(("\(name)", node.description)) }

        if let parameter = parameter { components.append((":\(parameter.name)", parameter.node.description)) }

        if let node = wildcard { components.append(("*", node.description)) }

        if let catchAll = catchAll {
            components.append(("**\(catchAll.name ?? "")", child: "└──● \(catchAll.handler)"))
        }

        if let handler = handler { components.append(("\(handler)", child: nil)) }

        let lastIndex = components.endIndex - 1
        let hasMoreThanOneChild = components.count > 1

        return components
            .enumerated()
            .map { index, component in

                let (name, child) = component
                let branchGlyph = index < lastIndex ? "├" : "└"

                guard let _child = child else { return branchGlyph + "──● " + name }

                let indentation = hasMoreThanOneChild && index < lastIndex ? "│  " : "   "
                return branchGlyph + "──┬ " + name + "\n" + _child.indented(with: indentation)
            }
            .joined(separator: "\n│\n")
    }
}

private extension String {

    func indented(with indentation: String = "\t") -> String {

        return split(separator: "\n").map { indentation + $0 }.joined(separator: "\n")
    }
}

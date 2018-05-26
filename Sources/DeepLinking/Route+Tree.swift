//
//  Route+Tree.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 15/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public extension Route {

    public enum TreeError: Swift.Error {
        case invalidRoute
        case duplicateEmptyComponent
        case conflictingParameterName(existing: String, new: String)
        case routeNotFound
        case invalidComponent(Component)
    }

    public indirect enum Tree<Handler> {

        // MARK: Nested types

        public enum Edge {
            case simple(Tree<Handler>)
            case parameter(String?, Tree<Handler>)
        }

        public typealias ChildEdges = [Component.Key : Edge]
        public typealias Match = (parameters: [String : String], handler: Handler)

        // MARK: Implementation

        case node(ChildEdges)
        case leaf(Handler)

        public init(route: [Component], handler: Handler) throws {
            switch route.first {
            case nil:
                self = .leaf(handler)
            case .empty?:
                guard route.count == 1 else { throw TreeError.invalidRoute }

                self = .leaf(handler)
            case let currentComponent?:
                let nextTree: Tree<Handler> = try Tree(route: Array(route.dropFirst()), handler: handler)
                let edges: ChildEdges = [currentComponent.key : currentComponent.edge(for: nextTree)]
                self = .node(edges)
            }
        }

        public mutating func add(route: [Component], handler: Handler) throws {
            let currentComponent = route.first ?? .empty
            let remainingRoute = Array(route.dropFirst())

            switch self {
            case var .node(edges):
                if let matchingChildEdge = edges[currentComponent.key] {
                    edges = try mergeTree(in: edges,
                                          matchingChildEdge: matchingChildEdge,
                                          currentComponent: currentComponent,
                                          remainingRoute: remainingRoute,
                                          handler: handler)
                } else {
                    edges = try createNewTree(in: edges,
                                              currentComponent: currentComponent,
                                              remainingRoute: remainingRoute,
                                              handler: handler)
                }

                self = .node(edges)
            case let .leaf(existingHandler):

                // turn leaf into a normal node, since this branch will grow
                let edges = try convertLeafToTree(existingHandler: existingHandler,
                                                  currentComponent: currentComponent,
                                                  remainingRoute: remainingRoute,
                                                  handler: handler)

                self = .node(edges)
            }
        }

        public mutating func remove(route: [Component]) throws -> Handler {
            switch self {
            case var .node(edges):
                let currentComponent = route.first ?? .empty
                let remainingRoute = Array(route.dropFirst())
                let childTree: Tree<Handler>

                // validate if we have an *exact* match with one of the edges
                switch edges[currentComponent.key] {
                case let .simple(nextTree)?: childTree = nextTree
                case let .parameter(nodeParameterName, nextTree)? :
                    guard case let .variable(componentParameterName) = currentComponent else {
                        fatalError("💥: Can't match .parameter edge with .empty or .constant component! 😱")
                    }

                    guard nodeParameterName == componentParameterName else { throw TreeError.routeNotFound }

                    childTree = nextTree
                case nil: throw TreeError.routeNotFound
                }

                return try removeFromChildTree(childTree,
                                               edges: edges,
                                               currentComponent: currentComponent,
                                               remainingRoute: remainingRoute)
            case let .leaf(handler):

                // only match if the route is empty or contains a *single* .empty component
                guard route.first ?? .empty == .empty, route.count <= 1 else {
                    throw TreeError.routeNotFound
                }

                // extract the handler and change to an empty node, effectively removing the handler from the tree
                self = .node([:])
                return handler
            }

        }

        public func match(route: [Component]) throws -> Match {
            switch self {
            case let .node(edges):
                let currentComponent = route.first ?? .empty
                let remainingRoute = Array(route.dropFirst())

                switch try matchChildEdge(in: edges, component: currentComponent) {
                case let .simple(childTree)?:
                    return try childTree.match(route: remainingRoute)
                case let .parameter(parameterName, childTree)?:
                    return try matchParameterEdge(parameterName: parameterName,
                                                  childTree: childTree,
                                                  currentComponent: currentComponent,
                                                  remainingRoute: remainingRoute)
                case nil:
                    throw TreeError.routeNotFound
                }
            case let .leaf(handler):

                // only match if the route is empty or contains a *single* .empty component
                guard route.first ?? .empty == .empty, route.count <= 1 else {
                    throw TreeError.routeNotFound
                }

                return ([:], handler)
            }
        }

        // MARK: Auxiliary

        private func createNewTree(in edges: ChildEdges,
                                   currentComponent: Component,
                                   remainingRoute: [Component],
                                   handler: Handler) throws -> ChildEdges {
            var newEdges = edges
            let newTree = try Tree<Handler>(route: remainingRoute, handler: handler)
            newEdges[currentComponent.key] = currentComponent.edge(for: newTree)
            return newEdges
        }

        private func mergeTree(in edges: ChildEdges,
                               matchingChildEdge: Edge,
                               currentComponent: Component,
                               remainingRoute: [Component],
                               handler: Handler) throws -> ChildEdges {
            var childTree: Tree<Handler>

            switch currentComponent {
            case .empty:
                // this node already has an empty edge, so reject addition
                throw TreeError.duplicateEmptyComponent
            case .constant:
                guard case let .simple(nextTree) = matchingChildEdge else {
                    fatalError("💥: Can't match .parameter edge with .constant component! 😱")
                }

                childTree = nextTree
            case let .variable(newParameterName):
                guard case let .parameter(existingParameterName, nextTree) = matchingChildEdge else {
                    fatalError("💥: Can't match .simple edge with .variable component! 😱")
                }

                guard existingParameterName == newParameterName else {
                    throw TreeError.conflictingParameterName(existing: existingParameterName ?? "*",
                                                             new: newParameterName ?? "*")
                }

                childTree = nextTree
            }

            try childTree.add(route: remainingRoute, handler: handler)

            var newEdges = edges
            newEdges[currentComponent.key] = currentComponent.edge(for: childTree)

            return newEdges
        }

        private func convertLeafToTree(existingHandler: Handler,
                                       currentComponent: Component,
                                       remainingRoute: [Component],
                                       handler: Handler) throws -> ChildEdges {
            if case .empty = currentComponent {
                // leaves cannot grow with an already empty component
                throw TreeError.duplicateEmptyComponent
            }

            let newTree = try Tree<Handler>(route: remainingRoute, handler: handler)
            return [.empty : .simple(.leaf(existingHandler)),
                    currentComponent.key : currentComponent.edge(for: newTree)]
        }

        private mutating func removeFromChildTree(_ childTree: Tree<Handler>,
                                                  edges: ChildEdges,
                                                  currentComponent: Component,
                                                  remainingRoute: [Component]) throws -> Handler {
            var childTree = childTree
            let handler = try childTree.remove(route: remainingRoute)
            var newEdges = edges

            // remove the node completely if it became empty (a leaf matched), or update edges with new node
            if case let .node(nextTreeChildren) = childTree, nextTreeChildren.isEmpty {
                newEdges[currentComponent.key] = nil
            } else {
                newEdges[currentComponent.key] = currentComponent.edge(for: childTree)
            }

            self = .node(newEdges)
            return handler
        }

        private func matchChildEdge(in edges: ChildEdges, component: Component) throws -> Edge? {
            switch component.key {
            case .empty:
                // match empty values separately
                return edges[.empty]
            case .constant:
                // match constants first as their constant value, then match as variables (parameter/wildcard)
                return edges[component.key] ?? edges[.variable]
            case .variable:
                // routes should be matched against empty or constant values only
                throw TreeError.invalidComponent(component)
            }
        }

        private func matchParameterEdge(parameterName: String?,
                                        childTree: Tree<Handler>,
                                        currentComponent: Component,
                                        remainingRoute: [Component]) throws -> Match {
            let match = try childTree.match(route: remainingRoute)

            guard let parameterName = parameterName else { return match }

            var parameters = match.parameters

            guard case let .constant(parameterValue) = currentComponent else {
                assertionFailure("""
                    🔥: matched non `.constant` component \(currentComponent)
                    to `parameter(\(parameterName))` edge!
                    """)
                throw TreeError.routeNotFound
            }

            assert(parameters[parameterName] == nil, "🔥: duplicate variable in route!")
            parameters[parameterName] = parameterValue

            return (parameters, match.handler)
        }
    }
}

extension Route.Tree: CustomStringConvertible, CustomDebugStringConvertible {

    // MARK: CustomStringConvertible

    public var description: String {
        switch self {
        case .leaf(let handler): return ".leaf(\(handler))"
        case .node(let childs): return ".node(\(childs))"
        }
    }

    // MARK: CustomDebugStringConvertible

    public var debugDescription: String {
        switch self {
        case .leaf(let handler): return ".leaf(\(handler))"
        case .node(let childs): return ".node(\(childs.debugDescription))"
        }
    }
}

extension Route.Tree.Edge: CustomStringConvertible, CustomDebugStringConvertible {

    // MARK: CustomStringConvertible

    public var description: String {
        switch self {
        case .simple(let tree): return ".simple(\(tree))"
        case .parameter(let parameterName, let tree): return ".parameter(\(parameterName ?? "*"), \(tree))"
        }
    }

    // MARK: CustomDebugStringConvertible

    public var debugDescription: String {
        switch self {
        case .simple(let tree):
            return ".simple(\(tree.debugDescription))"
        case .parameter(let parameterName, let tree):
            return ".parameter(\(parameterName ?? "*"), \(tree.debugDescription))"
        }
    }
}

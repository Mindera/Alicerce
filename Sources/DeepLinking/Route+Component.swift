//
//  Route+Component.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 15/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public extension Route {

    public enum Component {
        case empty // for default handlers, e.g.: /home
        case constant(String)
        case variable(String?) // variables and wildcard (*)

        public init(component: String) {
            precondition(component.contains("/") == false, "💥: path components can't have any \"/\" characters!")

            switch component.first {
            case ":"?:
                let index = component.index(component.startIndex, offsetBy: 1)
                let parameterName = String(component[index...])

                assert(parameterName.isEmpty == false, "🔥: path component's parameter name is empty!")

                self = .variable(parameterName)
            case "*"?:
                assert(component.count == 1, "🔥: wildcard path component must contain a single '*'")
                self = .variable(nil)
            case nil:
                self = .empty
            default:
                self = .constant(component)
            }
        }

        public var key: Key {
            switch self {
            case .empty: return .empty
            case let .constant(value): return .constant(value)
            case .variable: return .variable
            }
        }

        public func edge<Handler>(for node: Tree<Handler>) -> Tree<Handler>.Edge {
            switch self {
            case .empty, .constant: return .simple(node)
            case let .variable(parameterName): return .parameter(parameterName, node)
            }
        }

        // MARK: Key

        public enum Key {
            case empty
            case constant(String)
            case variable
        }
    }
}

extension Route.Component: Hashable {

    // MARK: Hashable

    public var hashValue: Int {
        switch self {
        case .empty: return "\(type(of: self).empty)".hashValue
        case let .constant(value): return "\(type(of: self).constant)(\(value))".hashValue
        case let .variable(parameter): return "\(type(of: self).variable)(\(String(describing: parameter)))".hashValue
        }
    }

    public static func ==(lhs: Route.Component, rhs: Route.Component) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty): return true
        case let (.constant(lhsString), .constant(rhsString)): return lhsString == rhsString
        case let (.variable(lhsParameter), .variable(rhsParameter)): return lhsParameter == rhsParameter
        default: return false
        }
    }
}

extension Route.Component: ExpressibleByStringLiteral {

    // MARK: ExpressibleByStringLiteral

    public init(stringLiteral value: String) {
        self.init(component: value)
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(component: value)
    }

    public init(unicodeScalarLiteral value: String) {
        self.init(component: value)
    }
}

extension Route.Component: CustomStringConvertible, CustomDebugStringConvertible {

    // MARK: CustomStringConvertible

    public var description: String {
        switch self {
        case .empty: return ""
        case let .constant(value): return value
        case let .variable(value?): return ":" + value
        case .variable(nil): return "*"
        }
    }

    // MARK: CustomDebugStringConvertible

    public var debugDescription: String {
        switch self {
        case .empty: return ".empty"
        case let .constant(value): return ".constant(\(value))"
        case let .variable(value): return ".variable(\(value ?? "*"))"
        }
    }
}

extension Route.Component.Key: Hashable {

    // MARK: Hashable

    public var hashValue: Int {
        switch self {
        case .empty: return "\(type(of: self).empty)".hashValue
        case let .constant(value): return value.hashValue
        case .variable: return "\(type(of: self).variable)".hashValue
        }
    }

    public static func ==(lhs: Route.Component.Key, rhs: Route.Component.Key) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty), (.variable, .variable): return true
        case let (.constant(lhsString), .constant(rhsString)): return lhsString == rhsString
        default: return false
        }
    }
}

extension Route.Component.Key: CustomStringConvertible, CustomDebugStringConvertible {

    // MARK: CustomStringConvertible

    public var description: String {
        switch self {
        case .empty: return ".empty"
        case .constant(let string): return ".constant(\(string))"
        case .variable: return ".variable"
        }
    }

    // MARK: CustomDebugStringConvertible

    public var debugDescription: String {
        return description
    }
}

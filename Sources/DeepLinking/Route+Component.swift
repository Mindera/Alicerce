import Foundation

public extension Route {

    enum Component: Hashable {
        case empty // for default handlers, e.g.: /home
        case constant(String)
        case variable(String?) // variables and wildcard (*)

        public init(component: String) {
            precondition(component.contains("/") == false, "💥 Path components can't have any \"/\" characters!")

            switch component.first {
            case ":"?:
                let index = component.index(component.startIndex, offsetBy: 1)
                let parameterName = String(component[index...])

                assert(parameterName.isEmpty == false, "🔥 Path component's parameter name is empty!")

                self = .variable(parameterName)
            case "*"?:
                assert(component.count == 1, "🔥 Wildcard path component must contain a single '*'")
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

        public enum Key: Hashable {
            case empty
            case constant(String)
            case variable
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

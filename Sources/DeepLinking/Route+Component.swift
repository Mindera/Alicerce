import Foundation

public extension Route {

    /// A Route's path component.
    enum Component: Hashable {

        /// A constant path component.
        case constant(String)

        /// A dynamic parameter component, represented as `:parameterName`
        case parameter(String)

        /// A dynamic parameter component with discarded value, represented as `*`.
        case wildcard

        /// A dynamic parameter component that matches one or multiple values, consuming the remaining path.
        /// Represented as `**` with discarded value, or as `**parameterName` to capture the value.
        case catchAll(String?)

        /// Instantiates a new path component from a given string value.
        ///
        /// - Parameter component: The string value.
        public init(component: String) {

            precondition(component.contains("/") == false, "💥 Path components can't have any \"/\" characters!")

            switch component.first {
            case ":"?:
                let parameterIndex = component.index(component.startIndex, offsetBy: 1)
                let parameterName = String(component[parameterIndex...])

                precondition(parameterName.isEmpty == false, "🔥 Path component's parameter name is empty!")
                self = .parameter(parameterName)

            case "*"? where component.count == 1:
                self = .wildcard

            case "*"?:
                let secondIndex = component.index(component.startIndex, offsetBy: 1)
                precondition(component[secondIndex] == "*", "🔥 Path component's wildcard can't have parameter name!")

                let parameterIndex = component.index(secondIndex, offsetBy: 1)
                let parameterName = String(component[parameterIndex...])

                self = .catchAll(parameterName.isEmpty ? nil : parameterName)

            default:
                self = .constant(component)
            }
        }
    }
}

extension Array where Element == Route.Component {

    /// A readable path representation of this instance.
    var path: String { return map { $0.description }.joined(separator: "/") }
}

// MARK: - CustomStringConvertible

extension Route.Component: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {

        self.init(component: value)
    }
}

extension Route.Component: CustomStringConvertible, CustomDebugStringConvertible {

    // MARK: CustomStringConvertible

    public var description: String {
        switch self {
        case .constant(let value):
            return value
        case .parameter(let value):
            return ":\(value)"
        case .wildcard:
            return "*"
        case .catchAll(let value?):
            return "**\(value)"
        case .catchAll:
            return "**"
        }
    }

    // MARK: CustomDebugStringConvertible

    public var debugDescription: String {
        switch self {
        case .constant(let value):
            return ".constant(\(value))"
        case .parameter(let value):
            return ".variable(\(value))"
        case .wildcard:
            return ".wildcard"
        case .catchAll(let value?):
            return ".catchAll(\(value))"
        case .catchAll(nil):
            return ".catchAll"
        }
    }
}

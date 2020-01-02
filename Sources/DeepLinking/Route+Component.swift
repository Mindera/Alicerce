import Foundation

public extension Route {

    /// An error produced when creating `Route.Component` instances.
    enum InvalidComponentError: Error {

        /// The value contains a forward slash, e.g. `/foo`.
        case unallowedForwardSlash

        /// The value consists of a parameter with an empty name, i.e. `:`.
        case emptyParameterName

        /// The value is an invalid wildcard, e.g. `*foo`.
        case invalidWildcard
    }

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
        /// - Throws: An `InvalidComponentError` error if the component is invalid.
        public init(component: String) throws {

            guard component.contains("/") == false else { throw InvalidComponentError.unallowedForwardSlash }

            switch component.first {
            case ":"?:
                let parameterIndex = component.index(component.startIndex, offsetBy: 1)
                let parameterName = String(component[parameterIndex...])

                guard parameterName.isEmpty == false else { throw InvalidComponentError.emptyParameterName }

                self = .parameter(parameterName)

            case "*"? where component.count == 1:
                self = .wildcard

            case "*"?:
                let secondIndex = component.index(component.startIndex, offsetBy: 1)

                guard component.count > 1, component[secondIndex] == "*" else {
                    throw InvalidComponentError.invalidWildcard
                }

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
    var path: String { map { $0.description }.joined(separator: "/") }
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

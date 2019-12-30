import Foundation
@testable import Alicerce

extension Route.TrieNode {

    static var empty: Route.TrieNode<Handler> { .init() }

    static func constant(_ name: String, node: Route.TrieNode<Handler>) -> Route.TrieNode<Handler> {

        .init(constants: [name: node])
    }

    static func constants(_ constants: [String: Route.TrieNode<Handler>]) -> Route.TrieNode<Handler> {

        .init(constants: constants)
    }

    static func parameter(_ name: String, node: Route.TrieNode<Handler>) -> Route.TrieNode<Handler> {

        .init(parameter: .init(name: name, node: node))
    }

    static func wildcard(_ node: Route.TrieNode<Handler>) -> Route.TrieNode<Handler> { .init(wildcard: node) }

    static func catchAll(_ name: String?, handler: Handler) -> Route.TrieNode<Handler> {

        .init(catchAll: .init(name: name, handler: handler))
    }

    static func handler(_ handler: Handler) -> Route.TrieNode<Handler> { .init(handler: handler) }
}

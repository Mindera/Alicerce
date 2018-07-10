import Foundation

public struct Token<Tag>: Hashable {

    fileprivate let value: UInt64
}

public final class Tokenizer<Tag> {

    private let current = Atomic(Token<Tag>(value: 0))

    public var next: Token<Tag> {
        return current.modify { token in
            let current = Token<Tag>(value: token.value)
            token = Token(value: token.value &+ 1)
            return current
        }
    }

    public init() {}
}

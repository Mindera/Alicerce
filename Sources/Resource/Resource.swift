import Foundation

public typealias ResourceMapClosure<U, V> = (U) throws -> V
public typealias ResourceErrorParseClosure<R, E: Swift.Error> = (R) -> E?

public protocol Resource {
    associatedtype Remote
    associatedtype Local
    associatedtype Error: Swift.Error

    var parse: ResourceMapClosure<Remote, Local> { get }
    var serialize: ResourceMapClosure<Local, Remote> { get }
    var errorParser: ResourceErrorParseClosure<Remote, Error> { get }
}

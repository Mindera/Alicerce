import Foundation

public protocol LogDestination: class {

    typealias ID = String

    var minLevel: Log.Level { get }
    var formatter: LogItemFormatter { get }
    var id: ID { get }

    func write(item: Log.Item, failure: @escaping (Error) -> ())
}

extension LogDestination {

    public var id: ID {
        return "\(type(of: self))"
    }
}

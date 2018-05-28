import Foundation

public protocol PerformanceMetricsTracker: class {

    typealias Identifier = String
    typealias Metadata = [String : Any]

    func begin(with identifier: Identifier)
    func end(with identifier: Identifier, metadata: Metadata?)
}

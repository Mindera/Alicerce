import Foundation
@testable import Alicerce

class MockPerformanceMetricsTracker: PerformanceMetricsTracker {

    var startInvoked: ((Identifier) -> Void)?
    var stopInvoked: ((Token<Tag>, Metadata?) -> Void)?

    var measureSyncInvokedClosure: ((PerformanceMetrics.Identifier, PerformanceMetrics.Metadata?) -> Void)?
    var measureInvokedClosure: ((PerformanceMetrics.Identifier, PerformanceMetricsTracker.Metadata?) -> Void)?

    let tokenizer = Tokenizer<Tag>()

    let id: UUID

    init(id: UUID = .init()) { self.id = id }

    func start(with identifier: Identifier) -> Token<Tag> {
        startInvoked?(identifier)
        return tokenizer.next
    }

    func stop(with token: Token<Tag>, metadata: Metadata?) {
        stopInvoked?(token, metadata)
    }

    func measure<T>(with identifier: Identifier, metadata: Metadata?, execute: () throws -> T) rethrows -> T {
        measureSyncInvokedClosure?(identifier, metadata)
        return try execute()
    }

    func measure<T>(with identifier: Identifier,
                    execute: (_ stop: @escaping (Metadata?) -> Void) throws -> T) rethrows -> T {
        return try execute { metadata in
            self.measureInvokedClosure?(identifier, metadata)
        }
    }
}

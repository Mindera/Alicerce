import Foundation

final class MockURLSessionDataTask: URLSessionDataTask {

    var mockTaskIdentifier: Int = 1337
    var mockState: URLSessionTask.State = .running
    var resumeInvokedClosure: (() -> Void)?
    var cancelInvokedClosure: (() -> Void)?

    override func resume() {
        resumeInvokedClosure?()
    }

    override func cancel() {
        cancelInvokedClosure?()
    }

    override var taskIdentifier: Int { mockTaskIdentifier }

    override var state: URLSessionTask.State { mockState }
}

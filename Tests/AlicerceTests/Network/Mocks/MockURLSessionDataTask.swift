import Foundation

final class MockURLSessionDataTask: URLSessionDataTask {

    var mockState: URLSessionTask.State = .running
    var resumeInvokedClosure: (() -> Void)?
    var cancelInvokedClosure: (() -> Void)?

    override func resume() {
        resumeInvokedClosure?()
    }

    override func cancel() {
        cancelInvokedClosure?()
    }

    override var state: URLSessionTask.State {
        return mockState
    }
}

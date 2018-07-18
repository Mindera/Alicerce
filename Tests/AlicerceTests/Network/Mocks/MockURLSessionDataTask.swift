import Foundation

final class MockURLSessionDataTask: URLSessionDataTask {

    var resumeInvokedClosure: (() -> Void)?
    var cancelInvokedClosure: (() -> Void)?

    override func resume() {
        resumeInvokedClosure?()
    }

    override func cancel() {
        cancelInvokedClosure?()
    }
}

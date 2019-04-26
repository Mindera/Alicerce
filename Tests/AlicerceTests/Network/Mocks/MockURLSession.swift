import Foundation
@testable import Alicerce

final class MockURLSession: URLSession {

    var mockDataTaskData: Data? = Data()
    var mockDataTaskError: Error? = nil
    var mockURLResponse: URLResponse = URLResponse()

    var mockDataTaskResumeInvokedClosure: ((URLRequest) -> Void)?
    var mockDataTaskCancelInvokedClosure: (() -> Void)?

    var mockAuthenticationChallenge: URLAuthenticationChallenge = URLAuthenticationChallenge()
    var mockAuthenticationCompletionHandler: Network.AuthenticationCompletionClosure = { _, _  in }

    var didInvokeFinishTasksAndInvalidate: (() -> Void)?

    private let _configuration: URLSessionConfiguration
    private let _delegate: URLSessionDelegate?
    private let _delegateQueue: OperationQueue

    private var mockDataTask: MockURLSessionDataTask?

    @objc
    override var configuration: URLSessionConfiguration { return _configuration }

    @objc
    override var delegate: URLSessionDelegate? { return _delegate }

    @objc
    override var delegateQueue: OperationQueue { return _delegateQueue }

    init(configuration: URLSessionConfiguration = .default,
         delegate: URLSessionDelegate?,
         delegateQueue queue: OperationQueue = OperationQueue()) {

        _configuration = configuration
        _delegate = delegate
        _delegateQueue = queue

        super.init()
    }

    override func dataTask(with request: URLRequest,
                           completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {

        let dataTask = MockURLSessionDataTask()

        dataTask.resumeInvokedClosure = { [weak self] in
            guard let strongSelf = self else { fatalError("🔥 `self` must be defined!") }

            strongSelf.delegateQueue.addOperation {
                strongSelf.mockDataTaskResumeInvokedClosure?(request)

                strongSelf.delegate?.urlSession?(strongSelf,
                                                 didReceive: strongSelf.mockAuthenticationChallenge,
                                                 completionHandler: strongSelf.mockAuthenticationCompletionHandler)

                completionHandler(strongSelf.mockDataTaskData, strongSelf.mockURLResponse, strongSelf.mockDataTaskError)
            }
        }

        dataTask.cancelInvokedClosure = { [weak self] in
            self?.mockDataTaskCancelInvokedClosure?()
        }

        // keep a strong reference to the task, otherwise it gets deallocated
        self.mockDataTask = dataTask

        return dataTask
    }

    override func finishTasksAndInvalidate() {

        didInvokeFinishTasksAndInvalidate?()
    }
}

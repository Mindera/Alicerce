import Foundation
import Result
@testable import Alicerce

final class MockNetworkCancelable: Cancelable {

    var mockIsCancelled: Bool = false
    var mockCancelClosure: (() -> Void)?

    var isCancelled: Bool { return mockIsCancelled }

    public func cancel() {
        mockCancelClosure?()
    }
}

final class MockNetworkStack: NetworkStack {
    typealias Request = URLRequest
    typealias Response = URLResponse
    typealias Remote = Data

    var mockData: Data?
    var mockError: Network.Error?
    var mockCancelable: MockNetworkCancelable = MockNetworkCancelable()

    let queue: DispatchQueue

    var beforeFetchCompletionClosure: (() -> Void)?
    var afterFetchCompletionClosure: (() -> Void)?

    init(queue: DispatchQueue = DispatchQueue(label: "com.mindera.alicerce.MockNetworkStack")) {

        self.queue = queue
    }

    func fetch<R>(resource: R, completion: @escaping Network.CompletionClosure<R.Remote>) -> Cancelable
    where R: NetworkResource & RetryableResource, R.Remote == Data, R.Request == URLRequest, R.Response == URLResponse {
        queue.async {
            self.beforeFetchCompletionClosure?()

            if let error = self.mockError {
                completion(.failure(error))
            } else if let data = self.mockData {
                completion(.success(data))
            } else {
                fatalError("🔥: either `mockData` or `mockError` must be defined!")
            }

            self.afterFetchCompletionClosure?()
        }

        return mockCancelable

    }
}

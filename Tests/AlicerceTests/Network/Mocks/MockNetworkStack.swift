import Foundation
@testable import Alicerce

final class MockNetworkStack: NetworkStack {
    typealias Request = URLRequest
    typealias Response = URLResponse
    typealias Remote = Data

    var mockResponse: URLResponse = URLResponse()
    var mockData: Data?
    var mockError: Network.Error?
    var mockCancelable: MockCancelable = MockCancelable()

    let queue: DispatchQueue

    var beforeFetchCompletionClosure: (() -> Void)?
    var afterFetchCompletionClosure: (() -> Void)?

    private var mockFetchWorkItem: DispatchWorkItem?

    init(queue: DispatchQueue = DispatchQueue(label: "com.mindera.alicerce.MockNetworkStack")) {

        self.queue = queue
    }

    func runMockFetch() {

        guard let fetchWorkItem = mockFetchWorkItem else {
            assertionFailure("🔥 `mockFetchWorkItem` not set! Call `fetch` first!")
            return
        }

        queue.async(execute: fetchWorkItem)

        mockFetchWorkItem = nil
    }

    func fetch<R>(resource: R, completion: @escaping Network.CompletionClosure<R.External>) -> Cancelable
    where R: NetworkStack.FetchResource, R.External == Data, R.Request == URLRequest, R.Response == URLResponse {

        mockFetchWorkItem = DispatchWorkItem {
            self.beforeFetchCompletionClosure?()

            if let error = self.mockError {
                completion(.failure(error))
            } else if let data = self.mockData {
                completion(.success(Network.Value(value: data, response: self.mockResponse)))
            } else {
                fatalError("🔥 Either `mockData` or `mockError` must be defined!")
            }

            self.afterFetchCompletionClosure?()
        }

        return mockCancelable
    }
}

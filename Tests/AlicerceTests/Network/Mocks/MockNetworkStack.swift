import Foundation
@testable import Alicerce

class MockNetworkStack<Resource, Remote, Response, FetchError: Error>: NetworkStack {

    typealias Resource = Resource
    typealias Remote = Remote
    typealias Response = Response
    typealias FetchError = FetchError

    var mockFetch: (Resource, @escaping FetchCompletionClosure) -> Cancelable

    init(mockFetch: @escaping (Resource, @escaping FetchCompletionClosure) -> Cancelable) {

        self.mockFetch = mockFetch
    }

    @discardableResult
    func fetch(resource: Resource, completion: @escaping FetchCompletionClosure) -> Cancelable {

        mockFetch(resource, completion)
    }
}

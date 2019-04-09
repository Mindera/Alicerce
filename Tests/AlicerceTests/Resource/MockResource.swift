import Foundation
import Result
@testable import Alicerce

struct MockResource<T>: NetworkResource & RetryableResource & PersistableResource & StrategyFetchResource {

    typealias Remote = Data
    typealias Local = T

    typealias Request = URLRequest
    typealias Response = URLResponse
    typealias APIError = MockAPIError

    enum MockError: Swift.Error { case 💣, 🧨 }
    enum MockAPIError: Swift.Error { case 💩 }

    // Mocks

    var mockParse: ParseClosure = { _ in throw MockError.💣 }
    var mockSerialize: SerializeClosure = { _ in throw MockError.🧨 }
    var mockParseAPIError: ParseAPIErrorClosure = { _, _ in return MockAPIError.💩 }

    var didInvokeMakeRequest: (() -> Void)?
    var didInvokeMakeRequestHandler: ((Cancelable) -> Void)?
    var mockMakeRequest: Result<Request, AnyError> = .success(URLRequest(url: URL(string: "https://mindera.com")!))

    var mockRetryPolicies: [ResourceRetry.Policy<Remote, Request, Response>] = []

    var mockPersistenceKey: String = "💽"

    var mockStrategy: StoreFetchStrategy = .networkThenPersistence

    // Resource

    var parse: ParseClosure { return mockParse }
    var serialize: SerializeClosure { return mockSerialize }

    // NetworkResource

    var parseAPIError: ParseAPIErrorClosure { return mockParseAPIError }
    static var empty: Remote { return Data() }

    @discardableResult
    func makeRequest(_ handler: @escaping MakeRequestHandler) -> Cancelable {

        didInvokeMakeRequest?()

        let cancelable = handler(mockMakeRequest)

        didInvokeMakeRequestHandler?(cancelable)

        return cancelable
    }

    // RetryableResource

    var retryErrors: [Swift.Error] = []
    var totalRetriedDelay: ResourceRetry.Delay = 0
    var retryPolicies: [ResourceRetry.Policy<Remote, Request, Response>] { return mockRetryPolicies }

    // PersistableResource

    var persistenceKey: Persistence.Key { return mockPersistenceKey }

    // StrategyFetchResource

    var strategy: StoreFetchStrategy { return mockStrategy }
}

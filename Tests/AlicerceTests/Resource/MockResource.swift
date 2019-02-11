import Foundation
import Result
@testable import Alicerce

struct MockResource<T>: NetworkResource & RetryableResource & PersistableResource & StrategyFetchResource {

    typealias Remote = Data
    typealias Local = T
    typealias Error = MockAPIError

    typealias Request = URLRequest
    typealias Response = URLResponse

    enum MockError: Swift.Error { case 💣, 🧨 }
    enum MockAPIError: Swift.Error { case 💩 }

    // Mocks

    var mockParse: (Remote) throws -> Local = { _ in throw MockError.💣 }
    var mockSerialize: (Local) throws -> Remote = { _ in throw MockError.🧨 }
    var mockErrorParser: (Remote) -> Error? = { _ in return MockAPIError.💩 }

    var didInvokeMakeRequest: (() -> Void)?
    var didInvokeMakeRequestHandler: ((Cancelable) -> Void)?
    var mockMakeRequest: Result<Request, AnyError> = .success(URLRequest(url: URL(string: "https://mindera.com")!))

    var mockRetryPolicies: [ResourceRetry.Policy<Remote, Request, Response>] = []

    var mockPersistenceKey: String = "💽"

    var mockStrategy: StoreFetchStrategy = .networkThenPersistence

    // Resource

    var parse: (Remote) throws -> Local { return mockParse }
    var serialize: (Local) throws -> Remote { return mockSerialize }
    var errorParser: (Remote) -> Error? { return mockErrorParser }

    // NetworkResource
    
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

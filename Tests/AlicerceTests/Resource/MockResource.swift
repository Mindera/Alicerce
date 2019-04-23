import Foundation
import Result
@testable import Alicerce

struct MockResource<T>: RetryableNetworkResource & EmptyExternalResource & ExternalErrorDecoderResource &
DecodableResource & PersistableResource & NetworkStoreStrategyFetchResource {

    typealias Internal = T
    typealias External = Data

    typealias Request = URLRequest
    typealias Response = URLResponse

    typealias RetryMetadata = (request: Request, payload: External?, response: Response?)

    typealias Error = MockAPIError
    typealias ExternalMetadata = Response

    enum MockError: Swift.Error { case 💣, 🧨 }
    enum MockAPIError: Swift.Error { case 💩 }

    // Mocks

    var mockDecode: DecodeClosure = { _ in throw MockError.💣 }
    var mockDecodeError: DecodeErrorClosure = { _, _ in return MockAPIError.💩 }

    var didInvokeMakeRequest: (() -> Void)?
    var didInvokeMakeRequestHandler: ((Cancelable) -> Void)?
    var mockMakeRequest: Result<Request, AnyError> = .success(URLRequest(url: URL(string: "https://mindera.com")!))

    var mockRetryPolicies: [RetryPolicy] = []

    var mockPersistenceKey: String = "💽"

    var mockStrategy: NetworkStoreFetchStrategy = .networkThenPersistence

    // NetworkResource

    @discardableResult
    func makeRequest(_ handler: @escaping MakeRequestHandler) -> Cancelable {

        didInvokeMakeRequest?()

        let cancelable = handler(mockMakeRequest)

        didInvokeMakeRequestHandler?(cancelable)

        return cancelable
    }

    // RetryableResource

    var retryErrors: [Swift.Error] = []
    var totalRetriedDelay: Retry.Delay = 0
    var retryPolicies: [RetryPolicy] { return mockRetryPolicies }

    // ExternalErrorDecoderResource

    var decodeError: DecodeErrorClosure { return mockDecodeError }

    // DecodableResource

    var decode: DecodeClosure { return mockDecode }

    // PersistableResource

    var persistenceKey: Persistence.Key { return mockPersistenceKey }

    // NetworkStoreStrategyFetchResource

    var strategy: NetworkStoreFetchStrategy { return mockStrategy }
}

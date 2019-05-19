//: [Previous](@previous)

import Alicerce
import Foundation
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

// Certificate Pinning

// for now, use the expiration date from the certificate itself
let gitHubRootExpirationDate = ISO8601DateFormatter().date(from: "2031-11-10T00:00:00Z")!

let gitHubPolicy = try ServerTrustEvaluator.PinningPolicy(
    domainName: "github.com",
    includeSubdomains: true,
    expirationDate: gitHubRootExpirationDate,
    pinnedHashes: ["WoiWRyIOVNa9ihaBciRSC7XHjliYS9VwUGOIud4PB18="], // DigiCertHighAssuranceEVRootCA
    enforceBackupPin: false) // we should ideally have a backup pin that's not in the chain to avoid bricking clients

let configuration = try ServerTrustEvaluator.Configuration(pinningPolicies: [gitHubPolicy],
                                                           certificateCheckingOrder: .rootToLeaf,
                                                           allowNotPinnedDomains: true,
                                                           allowExpiredDomainPolicies: true)

let serverTrustEvaluator = try ServerTrustEvaluator(configuration: configuration)


// Network Stack

let network = Network.URLSessionNetworkStack(authenticationChallengeHandler: serverTrustEvaluator,
                                             retryQueue: DispatchQueue(label: "com.alicerce.network.retry-queue"))

network.session = URLSession(configuration: .default,
                             delegate: network,
                             delegateQueue: nil)

// API Error

enum GitHubAPIError: Error, Decodable {

    case generic(message: String)

    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let message = try container.decode(String.self, forKey: .message)

        self = .generic(message: message)
    }

    private enum CodingKeys: String, CodingKey {
        case message
    }
}

// Endpoint

enum GitHubEndpoint: HTTPResourceEndpoint {

    case repo(owner: String, name: String)
    case repoCollaborators(owner: String, name: String)
    case nonExistent

    var method: HTTP.Method {
        switch self {
        case .repo, .repoCollaborators, .nonExistent:
            return .GET
        }
    }

    var baseURL: URL {
        return URL(string: "https://api.github.com")!
    }

    var path: String? {
        switch self {
        case .repo(let owner, let name):
            return "/repos/\(owner)/\(name)"
        case .repoCollaborators(let owner, let name):
            return "/repos/\(owner)/\(name)/collaborators"
        case .nonExistent:
            return "/non/existent"
        }
    }

    var headers: HTTP.Headers? {
        return ["Accept": "application/vnd.github.v3+json"]
    }
}

// Resource

struct GitHubResource<T: Decodable>: HTTPNetworkResource & RetryableNetworkResource & EmptyExternalResource &
ExternalErrorDecoderResource {

    typealias Internal = T
    typealias External = Data

    typealias Request = URLRequest
    typealias Response = URLResponse

    typealias Endpoint = GitHubEndpoint

    typealias RetryMetadata = (request: Request, payload: External?, response: Response?)

    typealias Error = GitHubAPIError
    typealias ExternalMetadata = Response

    // HTTPNetworkResource

    let endpoint: Endpoint

    // RetryableResource

    var retryErrors: [Swift.Error] = []
    var totalRetriedDelay: Retry.Delay = 0
    let retryPolicies: [RetryPolicy]

    // ExternalErrorDecoderResource

    var decodeError: DecodeErrorClosure = { data, _ in
        
        guard let data = data else { return nil }
        return try? JSONDecoder().decode(Error.self, from: data)
    }

    init(endpoint: Endpoint, retryPolicies: [RetryPolicy] = []) {

        self.endpoint = endpoint
        self.retryPolicies = retryPolicies
    }
}

// Model

struct GitHubRepo: Decodable {
    var name: String
    var fullName: String
    var stars: Int

    private enum CodingKeys: String, CodingKey {
        case name
        case fullName = "full_name"
        case stars = "stargazers_count"
    }
}

struct Dummy: Decodable {}

// Request

let repoResource = GitHubResource<GitHubRepo>(endpoint: .repo(owner: "Mindera", name: "Alicerce"))

network.fetch(resource: repoResource) { result in

    switch result {
    case .success(let value):
        String(bytes: value.value, encoding: .utf8)
    case .failure(.api(let apiError as GitHubAPIError, let statusCode, let response)):
        apiError
        statusCode
        response
    case .failure(let error):
        error
    }
}

// failing request

let nonExistentResource = GitHubResource<Dummy>(endpoint: .nonExistent)

network.fetch(resource: nonExistentResource) { result in

    switch result {
    case .success(let value):
        String(bytes: value.value, encoding: .utf8)
    case .failure(.api(let apiError as GitHubAPIError, let statusCode, let response)):
        apiError
        statusCode
        response
    case .failure(let error):
        error
    }
}

// NetworkStore (via NetworkStack)

extension GitHubResource: DecodableResource & PersistableResource & NetworkStoreStrategyFetchResource {

    // DecodableResource

    var decode: DecodeClosure { return { try JSONDecoder().decode(T.self, from: $0) } }

    // PersistableResource

    var persistenceKey: Persistence.Key { return "💾" }

    // NetworkStoreStrategyFetchResource

    var strategy: NetworkStoreFetchStrategy { return .networkThenPersistence }
}

// used to facilitate disambiguation of fetch API's
typealias NetworkStoreResult<T> = Result<NetworkStoreValue<T>, NetworkPersistableStoreError>

network.fetch(resource: repoResource) { (result: NetworkStoreResult<GitHubRepo>) in

    switch result {
    case .success(let model):
        model.value
    case .failure(let error):
        error
    }
}

network.fetch(resource: nonExistentResource) { (result: NetworkStoreResult<Dummy>) in

    switch result {
    case .success(let model):
        model.value
    case .failure(let error):
        error
    }
}

// Decoding on the network stack's fetch (if we don't want to use a `NetworkStore`):

network.fetch(resource: repoResource) { result in

    switch result {
    case .success(let value):
        do {
            try repoResource.decode(value.value)
        } catch {
            error
        }
    case .failure(.api(let apiError as GitHubAPIError, let statusCode, let response)):
        apiError
        statusCode
        response
    case .failure(let error):
        error
    }
}

//: [Next](@next)

//: [Previous](@previous)

import Alicerce
import Foundation
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

// MARK: Certificate Pinning

// for now, use the expiration date from the certificate itself
let gitHubRootExpirationDate = ISO8601DateFormatter().date(from: "2031-11-10T00:00:00Z")!

let gitHubPolicy = try ServerTrustEvaluator.PinningPolicy(
    domainName: "github.com",
    includeSubdomains: true,
    expirationDate: gitHubRootExpirationDate,
    pinnedHashes: ["WoiWRyIOVNa9ihaBciRSC7XHjliYS9VwUGOIud4PB18="], // DigiCertHighAssuranceEVRootCA
    enforceBackupPin: false // we should ideally have a backup pin that's not in the chain to avoid bricking clients
)

let configuration = try ServerTrustEvaluator.Configuration(
    pinningPolicies: [gitHubPolicy],
    certificateCheckingOrder: .rootToLeaf,
    allowNotPinnedDomains: false,
    allowExpiredDomainPolicies: false
)

let serverTrustEvaluator = try ServerTrustEvaluator(configuration: configuration)

// MARK: - Network Stack

let network = Network.URLSessionNetworkStack(
    authenticationChallengeHandler: serverTrustEvaluator,
    retryQueue: DispatchQueue(label: "com.alicerce.network.retry-queue")
)

network.session = URLSession(
    configuration: .default,
    delegate: network,
    delegateQueue: nil
)

// MARK: API Error

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

// MARK: - Endpoint

enum GitHubEndpoint: HTTPResourceEndpoint {

    case repo(owner: String, name: String)
    case repoCollaborators(owner: String, name: String, affiliation: RepoAffiliation = .all)
    case nonExistent

    enum RepoAffiliation: String {
        case outside
        case direct
        case all
    }

    var method: HTTP.Method {
        switch self {
        case .repo, .repoCollaborators, .nonExistent:
            return .GET
        }
    }

    var baseURL: URL { URL(string: "https://api.github.com")! }

    var path: String? {
        switch self {
        case .repo(let owner, let name):
            return "/repos/\(owner)/\(name)"
        case .repoCollaborators(let owner, let name, _):
            return "/repos/\(owner)/\(name)/collaborators"
        case .nonExistent:
            return "/non/existent"
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .repo, .nonExistent:
            return nil
        case .repoCollaborators(_, _, let affiliation):
            return [URLQueryItem(name: "affiliation", value: affiliation.rawValue)]
        }
    }

    var headers: HTTP.Headers? { ["Accept": "application/vnd.github.v3+json"] }
}

// MARK: Resource helpers

extension Network.URLSessionResource {

    static func github(
        endpoint: GitHubEndpoint,
        interceptors: [URLSessionResourceInterceptor] = [],
        retryActionPriority: @escaping Retry.Action.CompareClosure = Retry.Action.mostPrioritary
    ) -> Self {

        self.init(
            baseRequestMaking: .endpoint(endpoint),
            errorDecoding: .json(GitHubAPIError.self),
            interceptors: interceptors
        )
    }
}

// MARK: - Models

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

struct GitHubRepoCollaborator: Decodable {

    var login: String
    var avatarURL: String

    private enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
    }
}

// MARK: basic request

network.fetch(resource: .github(endpoint: .repo(owner: "Mindera", name: "Alicerce"))) { result in

    switch result {
    case .success(let value):
        String(decoding: value.value, as: UTF8.self)
        value.response

    case .failure(.http(let statusCode, let apiError as GitHubAPIError, let response)):
        apiError
        statusCode
        response

    case .failure(let error):
        error
    }
}

network.fetchAndDecode(
    resource: .github(endpoint: .repo(owner: "Mindera", name: "Alicerce")),
    decoding: .json(GitHubRepo.self)
) { result in

    switch result {
    case .success(let value):
        value

    case .failure(.fetch(Network.URLSessionError.http(let statusCode, let apiError as GitHubAPIError, let response))):
        apiError
        statusCode
        response

    case .failure(let error):
        error
    }
}

// MARK: failing request (404 - resource not found)

network.fetch(resource: .github(endpoint: .nonExistent)) { result in

    switch result {
    case .success(let value):
        value

    case .failure(.http(let statusCode, let apiError as GitHubAPIError, let response)):
        apiError
        statusCode
        response

    case .failure(let error):
        error
    }
}

// MARK: failing request (retries)

let retryInterceptors: [URLSessionResourceInterceptor] = [
    Network.URLSessionRetryPolicy.backoff(
        .exponential(
            baseDelay: 0.1,
            scale: { delay, retry in delay * Double(retry) },
            until: .maxDelay(0.4)
        )
    ),
    Network.URLSessionRetryPolicy.maxRetries(3) // try setting to higher retries (e.g. 4) to trigger different retryError
]

network.fetch(resource: .github(endpoint: .nonExistent, interceptors: retryInterceptors)) { result in

    switch result {
    case .success(let value):
        value

    case .failure(.retry(let retryError, let state)):
        retryError
        state

    case .failure(let error):
        error
    }
}

// MARK: failing request (401 - requires authentication)

network.fetch(resource: .github(endpoint: .repoCollaborators(owner: "Mindera", name: "Alicerce"))) { result in

    switch result {
    case .success(let value):
        value

    case .failure(.retry(let retryError, let state)):
        retryError
        state

    case .failure(let error):
        error
    }
}

// MARK: authenticated request

final class GitHubAuthenticator: URLRequestAuthenticator {

    let personalAccessToken: String

    init(personalAccessToken: String) {

        self.personalAccessToken = personalAccessToken
    }

    @discardableResult
    func authenticateRequest(_ request: URLRequest, handler: @escaping AuthenticationHandler) -> Cancelable {

        // this is a basic example to show how to use an authenticator, using a hardcoded token
        // on a real app this would be a "proper" authenticator for the GitHub API (e.g. using OAuth)

        var request = request

        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Authorization"] = "token \(personalAccessToken)"
        request.allHTTPHeaderFields = headers

        return handler(.success(request))
    }

    func evaluateFailedRequest(
        _ request: URLRequest,
        data: Data?,
        response: URLResponse?,
        error: Error,
        retryState: Retry.State
    ) -> Retry.Action {

        // here we could intercept authentication errors (e.g. 401 Unauthorized) and trigger a reauthentication, while
        // instructing the resource to be retried accordingly (e.g. after a certain amount of time), or not (e.g. user
        // is logged out)
        return .none
    }
}

extension GitHubAuthenticator: URLSessionResourceInterceptor {}

// https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line
let authenticator = GitHubAuthenticator(personalAccessToken: "<#personalAccessToken#>")

network.fetchAndDecode(
    resource: .github(
        endpoint: .repoCollaborators(owner: "Mindera", name: "Alicerce", affiliation: .all),
        interceptors: [authenticator] + retryInterceptors
    ),
    decoding: .json([GitHubRepoCollaborator].self)
) { result in

    switch result {
    case .success(let value):
        value

    case .failure(.fetch(Network.URLSessionError.retry(let retryError, let state))):
        retryError
        state

    case .failure(let error):
        error
    }
}

// MARK: logged request

final class URLSessionResourceLogger: URLSessionResourceInterceptor {

    func interceptScheduledTask(withIdentifier identifier: Int, request: URLRequest, retryState: Retry.State) {

        print("🚀 Task #\(identifier) with URL: '\(request.url!)' (attempt #\(retryState.attemptCount)) scheduled...")
    }

    func interceptSuccessfulTask(
        withIdentifier identifier: Int,
        request: URLRequest,
        data: Data,
        response: URLResponse,
        retryState: Retry.State
    ) {

        print(
            """
            🎉 Task #\(identifier) with URL: '\(request.url!)' (attempt #\(retryState.attemptCount)) \
            completed successfully!
            """
        )
    }

    func interceptFailedTask(
        withIdentifier identifier: Int,
        request: URLRequest,
        data: Data?,
        response: URLResponse?,
        error: Network.URLSessionError,
        retryState: Retry.State
    ) -> Retry.Action {

        print(
            """
            💥 Task #\(identifier) with URL: '\(request.url!)' (attempt #\(retryState.attemptCount)) \
            failed with error: \(error.localizedDescription)!
            """
        )
        return .none
    }
}

let resourceLogger = URLSessionResourceLogger()

network.fetchAndDecode(
    resource: .github(
        endpoint: .repoCollaborators(owner: "Mindera", name: "Alicerce", affiliation: .all),
        interceptors: [resourceLogger, authenticator] + retryInterceptors
    ),
    decoding: .json([GitHubRepoCollaborator].self)
) { result in

    switch result {
    case .success(let value):
        value

    case .failure(.fetch(Network.URLSessionError.retry(let retryError, let state))):
        retryError
        state

    case .failure(let error):
        error
    }
}

//: [Next](@next)

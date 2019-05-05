# Network

The **network layer**, represented by the [`Network`][Network] type, serves as a namespace encapsulating the different pieces required to deal with core networking operations.

The core element is the network stack, acting as the main entry point for any networking operations. In its turn, a stack can have a configuration that may provide additional functionality to the base implementation, such as a server trust validator or request interceptors.

## Concepts

### Network Stack

The **network stack**, represented by the [`NetworkStack`][NetworkStack] protocol, is the centerpiece of a network layer. 

This protocol has three associated types:

* `Remote` - the remote payload's raw type, typically a byte buffer representation like `Data`. 
* `Request` - the underlying network client's request type, like `URLRequest` on a `URLSession`.
* `Response` - the underlying network client's response type, like `URLResponse` on a `URLSession`.

It provides a [`FetchResource`](#resource) typealias for the combined protocols `RetryableNetworkResource & EmptyExternalResource & ExternalErrorDecoderResource`, which define the set of capabilities required by the network stack to perform a network request (detailed below).

It enforces a single function `fetch` that represents a network request, which as its name implies fetches a [`FetchResource`](#resource) and then calls a completion block with a result, which is either a successful value (wrapping the remote data and response objects) or a failed one (wrapping a network error). 

#### `URLSessionNetworkStack`

Although one can conform to the `NetworkStack` protocol to create a network stack from scratch, Alicerce provides a default stack implementation to handle HTTP requests, represented by the [`URLSessionNetworkStack`][URLSessionNetworkStack] class, which should cover most of the use cases. Internally, this stack is backed by a `URLSession`.

To be instantiated, a `URLSessionNetworkStack` requires the following dependencies:

* The **authentication challenge handler**, represented by the [`AuthenticationChallengeHandler`][AuthenticationChallengeHandler] protocol, has a single method for handling challenges from a server requiring authentication from the client (e.g. establishing an encrypted TLS session).

  * The [`ServerTrustEvaluator`][ServerTrustEvaluator] is an implementation of a `AuthenticationChallengeHandler` that performs [HTTP Public Key Pinning](#setting-up-ssltls-public-key-pinning) (HPKP) validation, based on [RFC 7469](https://tools.ietf.org/html/rfc7469) (not strict), by pinning the Certificates' Subject Public Key Info (SPKI).

* The **request interceptors**, as the name suggests, can intercept requests as well as their respective responses. An interceptor, represented by the [`RequestInterceptor`][RequestInterceptor] protocol, defines a method to be invoked for each situation. In other words, this means that any request and respective response can be modified by each interceptor before the network stack executes and returns it, respectively. It's useful for logging purposes, or to measure performance, for instance. 

* The **retry queue**, represented by a `DispatchQueue`, is the queue that will be used by the network stack to reschedule (retry) any resources that have failed and a delay is defined by the resource's retry policies, via a `asyncAfter()` call.

### Resource

The resource concept is the "work unit" of our Network layer, and abstracts an object that can have multiple representations (e.g. local, remote), capabilities and requirements. These multiple capabilities and requirements are spread across multiple protocols, that either build upon each other or are combined to define the desired behavior for each scenario.

In the case of fetching an object from the network via a `NetworkStack.fetch`, we are required to pass in a `NetworkStack.FetchResource` (`RetryableNetworkResource & EmptyExternalResource & ExternalErrorDecoderResource`). Let's break it down into the underlying protocols and requirements:

* [`Resource`][Resource] protocol: represents an object which has an `Internal` representation (i.e. local, like your Model type).

  * [`ExternalResource`][ExternalResource] protocol: represents a `Resource` that also has an `External` representation (i.e. remote, like `Data`).

    * [`RequestResource`][RequestResource] protocol: represents an `ExternalResource` that can be fetched by a `Request` object (i.e. like `URLRequest`).

        * [`NetworkResource`][NetworkResource] protocol: represents a `RequestResource` that can be fetched from the network. It defines a `Response` object (i.e. like `URLResponse`) and a single function `makeRequest` to generate requests asynchronously.

    * [`EmptyExternalResource`][EmptyExternalResource] protocol: represents an `ExternalResource` that defines an empty `External` instance, to be used when an external representation must be returned (e.g. returning a non `nil` value on 204/205 HTTP status codes).

    * [`ExternalErrorDecoderResource`][ExternalErrorDecoderResource] protocol: represents an `ExternalResource` that can decode custom errors from `External` representations and metadata. It defines a custom `Error` type, and an `ExternalMetadata` type to contain additional information (e.g. response object) which is passed in to the `decodeError` closure when trying to extract custom errors (e.g. API specific errors) on failed requests.

* [`RetryableResource`][RetryableResource] protocol: represents an object that can be retried after failing an operation, according to a defined set of `retryPolicies`. It defines a `RetryMetadata` type to represent additional information passed in when determining whether to retry an operation or not by the function `shouldRetry()`. Auxiliary properties `retryErrors`, `totalRetriedDelay` are also required to keep a record of all failures (and retries).

  * [`RetryableNetworkResource`][RetryableNetworkResource] protocol: represents a `RetryableResource` that is also a `NetworkResource`, where the `RetryMetadata` is tailored to evaluating failed network requests. It consists of a tuple defined as `(request: Request, payload: External?, response: Response?)`.

When a type conform to the above protocols, it has met the necessary requirements to be fetched on a `NetworkStack`. Whew! 

#### `HTTPNetworkResource `

Considering that the most common use case will be to perform network requests via HTTP on a `URLSessionNetworkStack`, we have created some additional protocols to make our life easier while avoiding some duplication:

* [`HTTPResourceEndpoint`][HTTPResourceEndpoint] protocol: represents an HTTP resource's endpoint and contains all the components required to create an HTTP request. It provides an extension to generate `URLRequest`'s from via a `request` property.

* [`BaseRequestResource`][BaseRequestResource] protocol: represents a `RequestResource` that provides a `baseRequest` to be fetched. 
  
  > The `NetworkResource` protocol contains an extension that provides a default implementation of `makeRequest` when `Self` also conforms to `BaseRequestResource`, by returning the `baseRequest`.

* [`HTTPNetworkResource`][HTTPNetworkResource] protocol: represents a `NetworkResource` and `BaseRequestResource` that is fetched over HTTP via `URLRequest`'s. It defines a `Endpoint: HTTPResourceEndpoint` type to represent the endpoint used by the resource to generate its requests, available on the property `endpoint`. It provides a default implementation of `baseRequest` by using `endpoint.request`.

With the above protocols, we can easily model an HTTP API and its multip[le endpoints, and create our own Resource type that interacts with it via a network stack.

#### `AuthenticatedRequestResource`

In the same way that network requests are commonly made via HTTP, it's also very frequent for them to require some form of authentication. To address these scenarios, another set of protocols was added to abstract common mechanics and make our life easier: 

* [`RequestAuthenticator`][RequestAuthenticator] protocol: represents an object that authenticates requests of a given type  `Request`, and also defines a custom authentication `Error` type. It defines a single function `authenticate` that authenticates requests asynchronously.

  * [`RetryableRequestAuthenticator`][RetryableRequestAuthenticator] protocol: represents a `RequestAuthenticator` that provides a retry policy rule to handle authentication errors. It defines the `Remote` and `Response` types that are then used to compose the `RetryMetadata` used by the authenticator's `RetryPolicy` (together with the `Request`). What enables the resource's authentication errors to be handled by the authenticator is the `retryPolicyRule` property, which should be injected as a `.custom` policy in the resource's `retryPolicies`.

    * [`RetryableURLRequestAuthenticator`][RetryableURLRequestAuthenticator] protocol: represents a `RetryableRequestAuthenticator`  specialized to authenticate `URLRequest`'s with `Data` remote type and `URLResponse`'s.

  * [`URLRequestAuthenticator`][URLRequestAuthenticator] protocol: represents a `RequestAuthenticator`  specialized to authenticate `URLRequest`'s.

* [`AuthenticatedRequestResource`][AuthenticatedRequestResource] protocol: represents a `RequestResource` that can be fetched using authenticated `Request`'s. It defines an `Authenticator: RequestAuthenticator` type that is used as the resource's `authenticator` property type. 

  > The `NetworkResource` protocol contains an extension that provides a default implementation of `makeRequest` when `Self` also conforms to `BaseRequestResource & AuthenticatedRequestResource`, by returning the `baseRequest` authenticated by the `authenticator`.

With the above protocols, we have the necessary infrastructure to fetch resources that require authentication. Additionally, since the authentication logic is only coupled to each Resource type and can (and should) be made asynchronously, it allows sharing the same network stack for all resources of an app, including authentication ones! 💪

### Error

The fetching action of an HTTP network stack, in case of error, should throw an error of the [`Network.Error`][Network.Error] type. This type encapsulates the different possible error scenarios:

* `noRequest`, when the resource's `makeRequest` fails.
* `http`, when the request failed with an HTTP protocol error (i.e. non 2xx status code).
* `api`, when the request failed with an HTTP protocol error (i.e. non 2xx status code), but a custom API error was produced by the resource's `decodeError` closure. The type of this error is the `Error` associated type of the resource which the stack is trying to fetch (provided via `ExternalErrorDecoderResource`).
* `noData`, when the response body is unexpectedly empty.
* `url`, when the request fails with a network failure (e.g. the `error` in a dataTask's completion handler is non `nil`).
* `badResponse`, when a valid HTTP response is missing.
* `retry`, when the request was not retried when evaluated by its retry policies after having failed with an error.

## Usage

### Setup

First, start with a network stack, the centerpiece of your network layer. For HTTP networking, it's simple as initializing a `URLSessionNetworkStack`. You need to inject a session into it before making any requests – not doing will result in a _fatal error_.

```swift
import Alicerce

let network = Network.URLSessionNetworkStack(retryQueue: DispatchQueue(label: "com.alicerce.network.retry-queue"))

network.session = URLSession(configuration: .default, delegate: network, delegateQueue: nil)
```

> Note that the delegate assigned to the session must be the network stack itself. A session without a delegate or a delegate that is anything but the stack itself results in a _fatal error_.
>
> _To preserve dependency injection, and since a session's delegate is only defined on its initialization, the session must be injected via a property._

Second, you need to create your implementation of a resource and associated types. The following example uses Swift's `Codable` to parse the models and custom API error.

To model our API and the endpoints we will use, we start by creating a custom `HTTPResourceEndpoint` type:

```swift
enum GitHubEndpoint: HTTPResourceEndpoint {

    case repo(owner: String, name: String)
    case repoCollaborators(owner: String, name: String)

    var method: HTTP.Method {
        switch self {
        case .repo, .repoCollaborators:
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
        }
    }

    var headers: HTTP.Headers? {
        return ["Accept": "application/vnd.github.v3+json"]
    }
}
```

To represent our custom API errors, we also create a type:

```swift
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
```

We can now create our resource type that conforms to the required protocols to be fetched on a network stack:

```swift
struct GitHubResource<T: Decodable>: HTTPNetworkResource & RetryableNetworkResource & EmptyExternalResource & ExternalErrorDecoderResource {

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
```

### Making a request

```swift

let resource = GitHubResource<GitHubRepo>(endpoint: .repo(owner: "Mindera", name: "Alicerce"))

network.fetch(resource: resource) { result in

    switch result {
    case .success(let value):
        // Valid response
    case .failure(.api(let apiError as GitHubAPIError, let statusCode, let response)):
        // API error
    case .failure(let error):
        // Network error
    }
}
```

That's it, we've successfully made your first network request with Alicerce 🎉

### Decoding a model from fetch result

Since our resource is already prepared to work with `Decodable`'s, parsing our model from the remote payload (`Data`) becomes quite straightforward if we update our `GitHubResource` to also be a `DecodableResource`. For the sake of simplicity (i.e. probably not the best performance), we can do this on an extension:

```swift

extension GitHubResource: DecodableResource {

    var decode: DecodeClosure { return { try JSONDecoder().decode(T.self, from: $0) } }
}
```

We can now define our model type for a particular endpoint:

```swift
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
```

And can now easily decode it inside our network stack's fetch completion:

```swift
let resource = GitHubResource<GitHubRepo>(endpoint: .repo(owner: "Mindera", name: "Alicerce"))

network.fetch(resource: resource) { result in

    switch result {
    case .success(let value):
        do {
            let repo = try repoResource.decode(value.value)
            // Shiny new model
        } catch {
            // Decoding error
        }
    case .failure(.api(let apiError as GitHubAPIError, let statusCode, let response)):
        // API error
    case .failure(let error):
        // Network error
    }
}
```

### Making an authenticated request

Our `GitHubResource` works perfectly with any *non authenticated* GitHub endpoint (e.g. like `.repo`), but will not be able to fetch any resource from an *authenticated* GitHub endpoint (e.g. like `.repoCollaborators`), since it will fail with an authentication error (e.g. a `401 Unauthorized`).

To address this, we can use a `RequestAuthenticator` that can authenticate GitHub requests when working alongside our resource. Assuming we will use OAuth2 authentication and we already have an OAuth2 client implementation, there are essentially two approaches:

1. Create our custom `RequestAuthenticator` type that wraps the OAuth2 client.
2. Extend the OAuth2 client to conform to `RequestAuthenticator`.

In this example, we will follow the 2nd approach:

```swift
import YourFavouriteOAuth2Lib

enum OAuth2ClientError: Error { 
    //... 
}

class OAuth2Client {

    typealias OAuth2Token = String

    // example async API to fetch the current OAuth2 token, or wait for one to be fetched
    func token(for request: URLRequest, completion: (Result<OAuth2Token, OAuth2ClientError>) -> Void) -> Cancelable {
        // ...
    }
}

extension OAuth2Client: RetryableURLRequestAuthenticator {

    typealias Error = OAuth2ClientError

    typealias Remote = Data
    typealias Request = URLRequest
    typealias Response = URLResponse

    var retryPolicyRule: RetryPolicy.Rule {

        return { [weak self] error, previousErrors, totalDelay, metadata in

            let (request, _, _) = metadata

            guard let self = self else { return .none }

            // extract the token used by the failed reqquest (if any)
            let rawToken = request.allHTTPHeaderFields?["Authorization"]
            let oAuthToken = rawToken?.split(separator: " ").last.flatMap(String.init)

            // handle the request's error and evaluate the action to take according to the current authentication state:
            // - trigger a (re)auth behind the scenes, and retry the request after some delay
            // - ignore the error as the token has already been refreshed, and retry the request
            // - mandate that the request should not be retried, as authentication failed
            // - ignore the error as the error is not related to authentication

            switch (error, self.state) {
            case ...:
            default:
                return .none
            }
        }
    }

    @discardableResult
    func authenticate(_ request: Request, handler: @escaping AuthenticationHandler) -> Cancelable {

        let cancelableBag = CancelableBag()

        // the client is responsible for providing the current token (if any), which it then injects on the request
        // ideally this should be made asynchronously so it doesn't block the network stack
        let cancelable = token(for: request) { result in

            switch result {
            case .failure(let error):
                // something went wrong, and the request can't be authenticated
                cancelableBag.add(cancelable: handler(.failure(error)))

            case .success(let token):
                // the request can be authenticated with the given token
                var request = request

                request.allHTTPHeaderFields = {
                    var httpHeaders = $0 ?? [:]

                    httpHeaders["Authorization"] = "token \(token)"

                    return httpHeaders
                }(request.allHTTPHeaderFields)

                cancelableBag.add(cancelable: handler(.success(request)))
            }
        }

        cancelableBag.add(cancelable: cancelable)

        return cancelableBag
    }
}
```

Once the authenticator is available, we can update our `GitHubResource` to have one and use it:

```swift
struct GitHubResource<T: Decodable>: HTTPNetworkResource & RetryableNetworkResource & EmptyExternalResource &
ExternalErrorDecoderResource & AuthenticatedRequestResource {

    typealias Internal = T
    typealias External = Data

    typealias Request = URLRequest
    typealias Response = URLResponse

    typealias Endpoint = GitHubEndpoint

    typealias RetryMetadata = (request: Request, payload: External?, response: Response?)

    typealias Error = GitHubAPIError
    typealias ExternalMetadata = Response

    typealias Authenticator = OAuth2Client

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

    // DecodableResource

    let decode: DecodeClosure = { return { try JSONDecoder().decode(T.self, from: $0) } }

    // AuthenticatedRequestResource

    let authenticator: Authenticator

    init(endpoint: Endpoint,
         authenticator: Authenticator,
         makeRetryPolicies: (_ authenticatorPolicy: RetryPolicy) -> [RetryPolicy] = { [$0] }) {

        self.endpoint = endpoint
        self.authenticator = authenticator

        // create the resource's retry policies passing in the authenticator's provided retry policy rule, so that the
        // authentication "loop" can be complete and the authenticator can react to authentication errors.
        // when creating retry policies, remember that the default policy evaluation process is order dependent.
        self.retryPolicies = makeRetryPolicies(.custom(authenticator.retryPolicyRule))
    }
}
```

If all went well, `GitHubResource`'s will now be authenticated when fetched on our network stack. 🔑

> Please note that if we don't need to react to authentication errors and retry requests based on them, we can use the simpler `URLRequestAuthenticator` instead, which only authenticates requests before them being performed.

### Setting up SSL/TLS Public Key Pinning

As mentioned before, Alicerce provides HTTP Public Key Pinning (HPKP) validation based on [RFC 7469](https://tools.ietf.org/html/rfc7469) (not strict), thru the `ServerTrustEvaluator` class. It works by pinning the Certificates' Subject Public Key Info (SPKI) SHA256 Base64 encoded hashes. Once you decide which certificate(s) you want to pin, you can obtain the SPKI data via either:

1. OpenSSL:

    ```
    openssl x509 -inform der -in <cert_name> -pubkey -noout |
    openssl pkey -pubin -outform der |
    openssl dgst -sha256 -binary |
    openssl enc -base64`
    ```
2. ssllabs.com

    Enter the server's URL -> analyse -> go to Certification Paths -> look for "Pin SHA256" entries

With the above information, you can then configure the `ServerTrustEvaluator` instance by providing it a `ServerTrustEvaluator.Configuration` object containing any number of `ServerTrustEvaluator.PinningPolicy`'s you want.

Continuing with our example, this could be a simple certificate pinning setup for our GitHub API client:

```swift
// for now, use the expiration date from the certificate itself as the policy's expiration date
let gitHubRootExpirationDate = ISO8601DateFormatter().date(from: "2031-11-10T00:00:00Z")!

let gitHubPolicy = try ServerTrustEvaluator.PinningPolicy(
    domainName: "github.com",
    includeSubdomains: true,
    expirationDate: gitHubRootExpirationDate,
    pinnedHashes: ["WoiWRyIOVNa9ihaBciRSC7XHjliYS9VwUGOIud4PB18="], // DigiCertHighAssuranceEVRootCA
    enforceBackupPin: false) // we should ideally have a backup pin that's not in the chain to avoid bricking clients

let configuration = try ServerTrustEvaluator.Configuration(pinningPolicies: [gitHubPolicy],
                                                           certificateCheckingOrder: .rootToLeaf,
                                                           allowNotPinnedDomains: false,
                                                           allowExpiredDomainPolicies: false)

let serverTrustEvaluator = try ServerTrustEvaluator(configuration: configuration)

let network = Network.URLSessionNetworkStack(authenticationChallengeHandler: serverTrustEvaluator,
                                             retryQueue: DispatchQueue(label: "com.alicerce.network.retry-queue"))

network.session = URLSession(configuration: .default, delegate: network, delegateQueue: nil)

// ...
```

And that's it! Our network stack is now protected by certificate pinning! 📌

For more information on Certificate and Public Key Pinning, please consult the following links:
- OWASP's [Certificate and Public Key Pinning page](https://www.owasp.org/index.php/Certificate_and_Public_Key_Pinning).
- Chris Palmer's [About Public Key Pinning blog page](https://noncombatant.org/2015/05/01/about-http-public-key-pinning/) (he's one of the authors of the [RFC 7469](https://tools.ietf.org/html/rfc7469)).

[Network]: ../Sources/Network/Network.swift
[NetworkStack]: ../Sources/Network/NetworkStack.swift
[Network.Configuration]: ../Sources/Network/Network.swift#L30
[AuthenticationChallengeHandler]: ../Sources/Network/AuthenticationChallengeHandler.swift
[ServerTrustEvaluator]: ../Sources/Network/Pinning/ServerTrustEvaluator.swift
[NetworkAuthenticator]: ../Sources/Network/NetworkAuthenticator.swift
[RequestInterceptor]: ../Sources/Network/RequestInterceptor.swift
[Resource]: ../Sources/Resource/Resource.swift
[ExternalResource]: ../Sources/Resource/Resource.swift#L11
[RequestResource]: ../Sources/Resource/RequestResource.swift
[RetryableResource]: ../Sources/Resource/RetryableResource.swift
[RetryableNetworkResource]: ../Sources/Network/Resource/RetryableNetworkResource.swift
[EmptyExternalResource]: ../Sources/Resource/EmptyExternalResource.swift
[ExternalErrorDecoderResource]: ../Sources/Resource/ExternalErrorDecoderResource.swift
[BaseRequestResource]: ../Sources/Resource/BaseRequestResource.swift
[NetworkResource]: ../Sources/Network/Resource/NetworkResource.swift
[HTTPResourceEndpoint]: ../Sources/Network/Resource/HTTPResourceEndpoint.swift
[HTTPNetworkResource]: ../Sources/Network/Resource/HTTPNetworkResource.swift
[AuthenticatedRequestResource]: ../Sources/Network/Resource/AuthenticatedRequestResource.swift
[RequestAuthenticator]: ../Sources/Network/RequestAuthenticator.swift
[RetryableRequestAuthenticator]: ../Sources/Network/RetryableRequestAuthenticator.swift#L30
[RetryableURLRequestAuthenticator]: ../Sources/Network/RetryableURLRequestAuthenticator.swift#L54
[URLRequestAuthenticator]: ../Sources/Network/RequestAuthenticator.swift#L49
[Network.Error]: ../Sources/Network/Network.swift#L26
[URLSessionNetworkStack]: ../Sources/Network/URLSessionNetworkStack.swift
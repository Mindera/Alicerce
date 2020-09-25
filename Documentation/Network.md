# Network

The **network layer**, represented by the [`Network`][Network] type, serves as a namespace encapsulating the different pieces required to deal with core networking operations.

The core element is the network stack, acting as the main entry point for any networking operations. In its turn, a stack can have a configuration that may provide additional functionality to the base implementation, such as a server trust validator or request interceptors.

## Concepts

### Network Stack

The **network stack**, represented by the [`NetworkStack`][NetworkStack] protocol, is the centerpiece of a network layer. 

This protocol has the following associated types:

* [`Resource`](#resource) - the remote resource representation, which acts as the stack's unit of work and provides any required capabilities, metadata and/or state (e.g. retries).
* `Remote` - the remote payload's raw type, typically a byte buffer representation like `Data`. 
* `Request` - the underlying network client's request type, like `URLRequest` on a `URLSession`.
* `Response` - the underlying network client's response type, like `URLResponse` on a `URLSession`.
* `FetchError` - the underlying network client's error type, like `URLError` on a `URLSession`.

It enforces a single function `fetch` that represents a network request, which as its name implies fetches a `Resource` and then calls a completion block with a result, which is either a successful value (wrapping the remote data and response objects) or a failed one (wrapping a network error).

It provides a default `fetchAndDecode` function implementation that builds upon `fetch` and requires an additional [`ModelDecoding`](#modeldecodingt-payload-metadata) instance to decode a network value upon a successful response into an arbitrary `T`.

#### `URLSessionNetworkStack`

Although one can conform to the `NetworkStack` protocol to create a network stack from scratch, Alicerce provides a default stack implementation to handle HTTP requests, represented by the [`URLSessionNetworkStack`][URLSessionNetworkStack] class, which should cover most of the use cases. Internally, this stack is backed by a `URLSession`.

To be instantiated, a `URLSessionNetworkStack` requires the following dependencies:

* The **authentication challenge handler**, represented by the [`AuthenticationChallengeHandler`][AuthenticationChallengeHandler] protocol, has a single method for handling challenges from a server requiring authentication from the client (e.g. establishing an encrypted TLS session).

  * The [`ServerTrustEvaluator`][ServerTrustEvaluator] is an implementation of a `AuthenticationChallengeHandler` that performs [HTTP Public Key Pinning](#setting-up-ssltls-public-key-pinning) (HPKP) validation, based on [RFC 7469](https://tools.ietf.org/html/rfc7469) (not strict), by pinning the Certificates' Subject Public Key Info (SPKI).

* The **retry queue**, represented by a `DispatchQueue`, is the queue that will be used by the network stack to reschedule (retry) any resources that have failed and a delay is defined by the resource's retry policies, via a `asyncAfter()` call.

The `URLSessionNetworkStack` constrains to the following types to conform to the `NetworkStack` protocol:

* [`Resource == URLSessionResource`](#urlsessionresource)
* `Remote == Data`
* `Response == URLResponse`
* [`FetchError == URLSessionError`](#urlsessionerror)

### Resource

The resource is the work unit of a Network stack, and abstracts an object that can have multiple representations (e.g. local, remote), capabilities and requirements. This allows each stack to require the set of behaviors it requires in a single concrete type, reducing the complexity of generic constraints.

#### `URLSessionResource`

To fetch data using a `URLSessionNetworkStack` we need to use a [`URLSessionResource`][URLSessionResource], which one can build by passing in the following dependencies:

* A [`BaseRequestMaking<URLRequest>`](#baserequestmakingrequest) instance: attempts to generate a new *base* `URLRequest` asynchronously every time a request is scheduled for this Resource. This base request is then processed by the interceptor chain to possibly be enriched/modified before being scheduled on the network.

* An [`ErrorDecoding<Data, URLResponse>`](#errordecodingpayload-metadata) instance: attempts to decode an arbitrary custom error (e.g. API error) from the payload and response whenever a request completes with an **unsuccessful** HTTP status code (i.e. _not_ 2xx).

* An array of [`URLSessionResourceInterceptor`](#urlsessionresourceinterceptor): as the name implies, these are objects that intercept key events in the lifecycle of a resource. They are chained and executed in order for each event, allow countless customizations in a resource's flow and business logic. Examples include passive interception for logging or performance measuring purposes, or active interception to support custom authentication or retries.

* A [`Retry.Action.CompareClosure`](#retries) closure: compares two `Retry.Action`s to determine which one should prevail when iterating over the retry actions returned by all the resource's interceptors upon request failure. A default implementation is already provided.

#### `HTTPResourceEndpoint`

The [`HTTPResourceEndpoint`][HTTPResourceEndpoint] protocol represents an HTTP resource's endpoint and contains the most frequent components required to create and configure a `URLRequest`, via a `makeRequest()` function. When conformed to by an `enum` type, it provides an elegant way to model the different endpoints of an API, while allowing complete control over the resulting `URLRequest`s.

It provides a protocol extension containing a default implementation of `makeRequest()`, which should serve most needs.

#### `BaseRequestMaking<Request>`

The [`BaseRequestMaking<Request>`][BaseRequestMaking] contains a single closure property `make` which attempts to generate a new *base* `Request` whenever required, while providing a `Cancelable` instance to allow cancelling any pending asynchronous work.

By being a struct and not a protocol (while modelling the same behavior), it greatly simplifies generics and allows easy default implementations via static factory methods. It currently provides an `.endpoint()` helper to build a `BaseRequestMaking<URLRequest>` from a particular [`HTTPResourceEndpoint`](#httpresourceendpoint) instance.

#### `ErrorDecoding<Payload, Metadata>`

The [`ErrorDecoding<Payload, Metadata>`][ErrorDecoding] type contains a single closure property `decode` which attempts to decode an arbitrary `Error` instance from a given `Payload?` and `Metadata` whenever a request completes with an **unsuccessful** HTTP status code (i.e. _not_ 2xx).

The `Payload` is the main source of data to perform the decoding, but on some scenarios an additional `Metadata` can be helpful (e.g. information contained in response headers).

By being a struct and not a protocol (while modelling the same behavior), it greatly simplifies generics and allows easy default implementations via static factory methods. It currently provides a `.json()` helper to build an `ErrorDecoding<Data, _>` that attempts to decode a particular `Decodable` error type `E` encoded in JSON using a `JSONDecoder`.

#### `URLSessionResourceInterceptor`

The [`URLSessionResourceInterceptor`][URLSessionResourceInterceptor] protocol represents an entity that intercepts specific events of a `URLSessionResource`'s lifecycle. These events are:

* Make Request: invoked before a particular resource's `URLRequest` is scheduled on the session via a `URLSessionDataTask`. The interceptor receives either the base request result (from the resource's `BaseRequestMaking` witness), or the result from the previous interceptor. The interceptor is then able to modify the request result or not, according to its needs (e.g. authenticate the request, or just log the event).

* Scheduled Task: invoked before a particular resource's `URLSessionDataTask` is scheduled. Interceptors can't modify any behavior at this point, so it's mostly suited for logging purposes and/or performance metrics.

* Successful Task: invoked when a particular resource's `URLSessionDataTask` has completed successfully. Interceptors can't modify any behavior at this point, so it's mostly suited for logging purposes and/or performance metrics.

* Failed Task: invoked when a particular resource's `URLSessionDataTask` has completed with an error. Interceptors receive information about the failure and current resource context, and should return a specific [`Retry.Action`](#retries) for the stack to perform for this resource. This allows complex behaviors to be created on a per `URLSessionResource` basis, like respond to authentication failures, or apply a retry policy. The event is processed by all elements in the interceptor chain, and the most prioritary retry action is obtained via the resource's `retryActionPriority` property. 

Alicerce already provides default `URLSessionResourceInterceptor` implementations on the following types:

* [`URLRequestAuthenticator`](#urlrequestauthenticator): provides default implementation to the make request and failed task events, to handle authentication.

* [`URLSessionRetryPolicy`](#retries): provides default protocol conformance and implements the failed task event, to apply a specific retry policy to a resource.

#### `URLRequestAuthenticator`

The [`URLRequestAuthenticator`][URLRequestAuthenticator] protocol represents an entity that handles authentication of `URLRequest`'s. The authenticator has two main entry points:
* Request authentication: invoked to authenticate a request before scheduling
* Request failure: invoked to handle and react to authentication failures, which allows the authenticator to trigger reauthentication under the hood as well as provide a specific retry action to apply to the request's parent operation (e.g. a `URLSessionResource`).

Can be used as an element of a `URLSessionResource`'s interceptor chain.

### Retries

Alicerce provides a set of types tailored to handling retries of arbitraty operations, namespaced under the [`Retry`][Retry] `enum`. The types are:

* `Retry.Action`: represents the action to take after evaluating a retry policy. It can be:
  * `none`: don't take any action.
  * `noRetry(Retry.Error)`: don't retry the operation due to the specified error.
  * `retry`: retry the operation immediately.
  * `retryAfter(Retry.Delay)`: retry the operation after the specified delay.

* `Retry.Error`: represents an error that caused the operation to not be retried:
  * `retries(Retries)`: the maximum amount of retries have been reached.
  * `delay(Delay)`: the maximum retry delay has been reached.
  * `custom(Error)`: an arbitrary error has prevented the operation from being retried.

* `Retry.State`: contains the retry state and history of an operation, so that policies can be correctly evaluated against. 

* `Retry.Policy<Metadata>`: models a policy to evaluate operations against. It can be:
  
  * `maxRetries(Retries)`: limit the total number of retries.
  * `backoff(Backoff)`: applies a backoff strategy to delay and limit retries until a particular truncation rule. Current available strategies are `constant` and `exponential`, and truncations are `maxRetries` and `maxDelay`.
  * `custom(Rule)`: applies a custom rule consisting of a closure.

  The `Metadata` generic type is used so that arbitrary data about the operation can be passed into custom rules, so that more complex behaviors can be achieved. As an example, `URLSessionResource` uses a [URLSessionRetryPolicy][URLSessionRetryPolicy], which is a typealias for `Retry.Policy<(URLRequest, Data?, URLResponse?)>`. This enables custom rules to inspect things like the request URL, payload or response headers, unlocking a fine grained control over the resulting retry action.

  Whenever an operation fails, a particular policy is evaluated using the `shouldRetry` function and produces a `Retry.Action`.

  Complex retry rulesets can be built by composing multiple policies (e.g. an array). Upon operation failure, these can be evaluated serially to obtain their respective retry actions from which a single "most prioritary" action emerges. A default implementation for this comparison is provided in the `Retry.Action.mostPrioritary()` static function. 

  Can be used as an element of a `URLSessionResource`'s interceptor chain.

#### `AuthenticatedRequestResource`

In the same way that network requests are commonly made via HTTP, it's also very frequent for them to require some form of authentication. To address these scenarios, another set of protocols was added to abstract common mechanics and make our life easier: 

* [`RequestAuthenticator`][RequestAuthenticator] protocol: represents an object that authenticates requests of a given type  `Request`, and also defines a custom authentication `Error` type. It defines a single function `authenticate` that authenticates requests asynchronously.

  * [`RetryableRequestAuthenticator`][RetryableRequestAuthenticator] protocol: represents a `RequestAuthenticator` that provides a retry policy rule to handle authentication errors. It defines the `Remote` and `Response` types that are then used to compose the `RetryMetadata` used by the authenticator's `RetryPolicy` (together with the `Request`). What enables the resource's authentication errors to be handled by the authenticator is the `retryPolicyRule` property, which should be injected as a `.custom` policy in the resource's `retryPolicies`.

    * [`RetryableURLRequestAuthenticator`][RetryableURLRequestAuthenticator] protocol: represents a `RetryableRequestAuthenticator`  specialized to authenticate `URLRequest`'s with `Data` remote type and `URLResponse`'s.

  * [`URLRequestAuthenticator`][URLRequestAuthenticator] protocol: represents a `RequestAuthenticator`  specialized to authenticate `URLRequest`'s.

* [`AuthenticatedRequestResource`][AuthenticatedRequestResource] protocol: represents a `RequestResource` that can be fetched using authenticated `Request`'s. It defines an `Authenticator: RequestAuthenticator` type that is used as the resource's `authenticator` property type. 

  > The `NetworkResource` protocol contains an extension that provides a default implementation of `makeRequest` when `Self` also conforms to `BaseRequestResource & AuthenticatedRequestResource`, by returning the `baseRequest` authenticated by the `authenticator`.

With the above protocols, we have the necessary infrastructure to fetch resources that require authentication. Additionally, since the authentication logic is only coupled to each Resource type and can (and should) be made asynchronously, it allows sharing the same network stack for all resources of an app, including authentication ones! 💪

### Decoding

As mentioned above, the `NetworkStack` provides a `fetchAndDecode` function that automatically fetches and decodes a `Resource`, give  it's provided with a `ModelDecoding` witness. The failure type is a [`FetchAndDecodeError`](#fetchanddecodeerror) to allow the caller to differentiate the "origin" of the failure.

#### `ModelDecoding<T, Payload, Metadata>`

The [`ModelDecoding<T, Payload, Metadata>`][ModelDecoding] type contains a single closure property `decode` which attempts to decode an arbitrary `T` instance from a given `Payload` and `Metadata` whenever a request completes with a **successful** HTTP status code (i.e. 2xx, *except* 204 and 205 which expect empty bodies). 

The `Payload` is the main source of data to perform the decoding, but on some scenarios an additional `Metadata` can be helpful (e.g. information contained in response headers).

By being a struct and not a protocol (while modelling the same behavior), it greatly simplifies generics and allows easy default implementations via static factory methods. It currently provides an `.json()` helper to build an `Decoding<T, Data, _>` that attempts to decode a particular `Decodable` model `T` encoded in JSON using a `JSONDecoder`.

### Errors

#### `URLSessionError`

The fetching action of an HTTP network stack, in case of error, should throw an error of the [`URLSessionError`][URLSessionError] type. This type encapsulates the different possible error scenarios:

* `noRequest`, when the resource's `makeRequest` fails.
* `http`, when the request failed with an HTTP protocol error (i.e. non 2xx status code), and may contain a custom API error decoded by the resource's `errorDecoding` witness.
* `noData`, when the response body is unexpectedly empty.
* `url`, when the request fails with a network failure, expressed as an `URLError` (i.e. the `error` in a dataTask's completion handler is non `nil`).
* `badResponse`, when a valid HTTP response is missing.
* `retry`, when the request was _explicitly_ **not retried** when evaluated by its retry policies after having failed with an error.
* `cancelled`, when the fetch was cancelled via the `Cancelable` instance.

#### `FetchAndDecodeError`

The [`FetchAndDecodeError`][FetchAndDecodeError] is a simple error type used on `fetchAndDecode` calls and is used to differentiate between errors originating from either the fetch or decode operations. As such, it has just two cases which wrap an error each:
* `fetch(Error)`
* `decode(Error)`

## Usage

### Setup

Let's walk through the basic steps required to start making some requests with Alicerce. A similar setup is also available in a [Swift playground][Network.xcplaygroundpage] as a live example.

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
    case repoCollaborators(owner: String, name: String, affiliation: RepoAffiliation = .allg)

    enum RepoAffiliation: String {
        case outside
        case direct
        case all
    }

    var method: HTTP.Method {
        switch self {
        case .repo, .repoCollaborators:
            return .GET
        }
    }

    var baseURL: URL { URL(string: "https://api.github.com")! }

    var path: String? {
        switch self {
        case .repo(let owner, let name):
            return "/repos/\(owner)/\(name)"
        case .repoCollaborators(let owner, let name):
            return "/repos/\(owner)/\(name)/collaborators"
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .repo:
            return nil
        case .repoCollaborators(_, _, let affiliation):
            return [URLQueryItem(name: "affiliation", value: affiliation.rawValue)]
        }
    }

    var headers: HTTP.Headers? { ["Accept": "application/vnd.github.v3+json"] }
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

We can then create a helper to easily build `URLSessionResource`s for our API, so that we can fetch them on our network stack:

```swift
extension Network.URLSessionResource {

    static func github(
        endpoint: GitHubEndpoint,
        interceptors: [URLSessionResourceInterceptor] = [],
        retryActionPriority: @escaping Retry.Action.CompareClosure = Retry.Action.mostPrioritary
    ) -> Self {

        .init(
            baseRequestMaking: .endpoint(endpoint),
            errorDecoding: .json(GitHubAPIError.self),
            interceptors: interceptors
        )
    }
}
```

### Making a request

```swift
network.fetch(resource: .github(endpoint: .repo(owner: "Mindera", name: "Alicerce"))) { result in

    switch result {
    case .success(let value):
        // network value (raw payload + response)
    case .failure(.http(let statusCode, let apiError as GitHubAPIError, let response)):
        // API error
    case .failure(let error):
        // other error
    }
}
```

That's it, we've successfully made your first network request with Alicerce 🎉

### Decoding a model from fetch result

We have the JSON payload for a particular API, but we would really like to decode that data into an actual model type.

Let's define our model type for a particular endpoint:

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

Now, we can take advantage of the `NetworkStack`'s `fetchAndDecode` method to easily achieve our goal:

```swift
network.fetchAndDecode(
    resource: .github(endpoint: .repo(owner: "Mindera", name: "Alicerce")),
    decoding: .json(GitHubRepo.self)
) { result in

    switch result {
    case .success(let value):
        // decoded value (decoded model + response)
    case .failure(.fetch(Network.URLSessionError.http(let statusCode, let apiError as GitHubAPIError, let response))):
        // API error
    case .failure(let error):
        // other error
    }
}
```

### Retry requests on failure

Supporting retries on failure is really simple, and you just have to set up your retry policies as a part of the resource's interceptor chain:

```swift

// retry with an exponentially higher delay (0.1s x N) until we delayed for a total of 0.4s
let retryInterceptors: [URLSessionResourceInterceptor] = [
    Network.URLSessionRetryPolicy.backoff(
        .exponential(
            baseDelay: 0.1, 
            scale: { delay, retry in delay * Double(retry) }, 
            until: .maxDelay(0.4)
        )
    )
]

network.fetch(
    resource: .github(
        endpoint: .repo(owner: "Mindera", name: "Alicerce"),
        interceptors: retryInterceptors
    )
) { result in
    // ...
}
```

### Authenticate requests

Our default `URLSessionResource.github` resource works perfectly with any *non authenticated* GitHub endpoint (e.g. like `.repo`), but will not be able to fetch any resource from an *authenticated* GitHub endpoint (e.g. like `.repoCollaborators`), since it will fail with an authentication error (e.g. a `401 Unauthorized`).

To address this, we can use a `URLRequestAuthenticator` that will authenticate GitHub requests when working alongside our resource. Assuming we will use OAuth2 authentication and we already have an OAuth2 client implementation, there are essentially two approaches:

1. Create our custom `URLRequestAuthenticator` type that wraps the OAuth2 client.
2. Extend the OAuth2 client to conform to `URLRequestAuthenticator`.

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

extension OAuth2Client: URLRequestAuthenticator {

    @discardableResult
    func authenticateRequest(_ request: URLRequest, handler: @escaping AuthenticationHandler) -> Cancelable {

        let cancelableBag = CancelableBag()

        // the client is responsible for providing the current token (if any), which it then injects on the request
        // ideally this should be made asynchronously so it doesn't block the network stack
        cancelableBag += token(for: request) { result in

            switch result {
            case .failure(let error):
                // something went wrong, and the request can't be authenticated
                cancelableBag += handler(.failure(error))

            case .success(let token):
                // the request can be authenticated with the given token
                var request = request

                var httpHeaders = request.allHTTPHeaderFields ?? [:]
                httpHeaders["Authorization"] = "token \(token)"
                request.allHTTPHeaderFields = httpHeaders

                cancelableBag += handler(.success(request))
            }
        }

        return cancelableBag
    }

    func evaluateFailedRequest(
        _ request: URLRequest,
        data: Data?,
        response: URLResponse?,
        error: Error,
        retryState: Retry.State
    ) -> Retry.Action {

        // extract the token used by the failed request (if any)
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
```

Once the authenticator is available, we simply need to add it to our resource's interceptor chain for it to be used:

```swift
let authenticator = OAuth2Client(...)

network.fetchAndDecode(
    resource: .github(
        endpoint: .repoCollaborators(owner: "Mindera", name: "Alicerce", affiliation: .all),
        interceptors: [authenticator]
    ),
    decoding: .json([GitHubRepoCollaborator].self)
) { result in

    switch result {
    case .success(let value):
        // decoded value

    case .failure(.fetch(Network.URLSessionError.retry(let retryError, let state))):
        // API error

    case .failure(let error):
        // other error
    }
}
```

If all went well, the above resource will now be authenticated when fetched on our network stack. 🔑

> Please note that if we don't need to react to authentication errors and retry requests based on them, we can simply return `.none` in the `evaluateFailedRequest()` implementation.

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
    enforceBackupPin: false // we should ideally have a backup pin that's not in the chain to avoid bricking clients
) 

let configuration = try ServerTrustEvaluator.Configuration(
    pinningPolicies: [gitHubPolicy],
    certificateCheckingOrder: .rootToLeaf,
    allowNotPinnedDomains: false,
    allowExpiredDomainPolicies: false
)

let serverTrustEvaluator = try ServerTrustEvaluator(configuration: configuration)

let network = Network.URLSessionNetworkStack(
    authenticationChallengeHandler: serverTrustEvaluator,
    retryQueue: DispatchQueue(label: "com.alicerce.network.retry-queue")
)

network.session = URLSession(configuration: .default, delegate: network, delegateQueue: nil)

// ...
```

And that's it! Our network stack is now protected by certificate pinning! 📌

For more information on Certificate and Public Key Pinning, please consult the following links:
- OWASP's [Certificate and Public Key Pinning page](https://www.owasp.org/index.php/Certificate_and_Public_Key_Pinning).
- Chris Palmer's [About Public Key Pinning blog page](https://noncombatant.org/2015/05/01/about-http-public-key-pinning/) (he's one of the authors of the [RFC 7469](https://tools.ietf.org/html/rfc7469)).

[Network]: ../Sources/Network/Network.swift
[NetworkStack]: ../Sources/Network/NetworkStack.swift
[URLSessionNetworkStack]: ../Sources/Network/Network+URLSessionNetworkStack.swift
[AuthenticationChallengeHandler]: ../Sources/Network/AuthenticationChallengeHandler.swift
[ServerTrustEvaluator]: ../Sources/Network/Pinning/ServerTrustEvaluator.swift
[URLSessionResource]: ../Sources/Network/Network+URLSessionResource.swift
[HTTPResourceEndpoint]: ../Sources/Network/HTTPResourceEndpoint.swift
[BaseRequestMaking]: ../Sources/Network/Network+BaseRequestMaking.swift
[ErrorDecoding]: ../Sources/Network/Network+ErrorDecoding.swift
[URLSessionError]: ../Sources/Network/Network+URLSessionError.swift
[URLSessionRetryPolicy]: ../Sources/Network/Network.swift#L17
[URLRequestAuthenticator]: ../Sources/Network/URLRequestAuthenticator.swift
[URLSessionResourceInterceptor]: ../Sources/Network/URLSessionResourceInterceptor.swift
[ModelDecoding]: ../Sources/Shared/ModelDecoding.swift
[FetchAndDecodeError]: ../Sources/Shared/FetchAndDecodeError.swift
[Network.xcplaygroundpage]: ../Alicerce.playground/Pages/Network.xcplaygroundpage/Contents.swift

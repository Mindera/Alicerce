# Network

The **network layer**, represented by the [`Network`][Network] type, serves as a namespace encapsulating the different pieces required to deal with core networking operations.

The core element is the network stack, acting as the main entry point for any networking operations. In its turn, a stack has a configuration that may provide additional functionality to the base implementation, such as a server trust validator, an authenticator or even request interceptors.

## Concepts

### Network Stack

The **network stack**, represented by the [`NetworkStack`][NetworkStack] protocol, is the centerpiece of a network layer. 

This protocol enforces a single function that represents a network request, which fetches a [resource](#resource) and then calls a completion block, either with the successful result or throwing an error.


### Configuration

A **configuration**, represented by the [`Network.Configuration`][Network.Configuration] type, allows one to extend a network stack with additional optional functionality. It can have an authentication challenge handler, an authenticator, and request interceptors.

* The **authentication challenge handler**, represented by the [`AuthenticationChallengeHandler`][AuthenticationChallengeHandler] protocol, has a single method for handling challenges from a server requiring authentication from the client.

* The **network authenticator**, represented by the [`NetworkAuthenticator`][NetworkAuthenticator] protocol, authenticates requests and validates the corresponding responses as well.

* At last, the **request interceptors**, as the name suggests, can intercept requests (before the stack executes them), and can intercept the responses as well. An interceptor, represented by the [`RequestInterceptor`][RequestInterceptor] protocol, provides two methods, one to intercept the requests and another one to intercept the responses. In other words, this means that any request can be modified before the network stack executes it. In a like manner, any response can be modified before the stack returns it.


### Resource

A resource, represented by the [`NetworkResource`][NetworkResource] protocol, represents an action that one can take on an API. Ultimately, the network stack turns a resource into a network request.

> In its core, this protocol inherits from the [`Resource`][Resource] protocol, which has three associated types:
>
> * `Remote` - the raw type, typically, a byte buffer representation like Data. 
> * `Local` - the model type, a type-safe representation of the data.
> * `Error` - the error type used to represent API errors.
>
> Additionally, a resource has three closures:
>
> * The `parse` closure to transform the `Remote` type into the `Local` one.
> * The `serialize` closure to do the reverse, serializing the `Local` type into the `Remote`.
> * The `errorParser`  closure returns an optional error when a networking error occurs.

In the network stack, one can use the `NetworkResource` or one of the more complete representations of a resource that Alicerce provides: the **relative network resource**, represented by the [`RelativeNetworkResource`][RelativeNetworkResource] protocol, and the **static network resource**, represented by the [`StaticNetworkResource`][StaticNetworkResource] protocol.

Both are quite similar, but while the former always operates on relative paths on top of a static base URL, the latter operates on absolute paths.

These resources store the following data:

* HTTP method (e.g., `GET` or `POST`)
* HTTP header fields
* HTTP query
* HTTP body

Additionally, a relative resource stores a relative path, whereas a static resource stores a URL.


### Error

The fetching action of a stack, in case of error, should throw an error of the [`Network.Error`][Network.Error] type. This type encapsulates the different possible error scenarios:

* `http`, which represents an HTTP error and has an associated error code and an optional API error – the type of this error is the `Error` associated type of the resource which the stack is trying to fetch.
* `noData`, when the response is empty
* `url`, when the request fails
* `badResponse`, when a valid HTTP response is missing
* `authenticator`, when the authentication fails (for stacks with an authenticator configured)


## Usage

Although one can conform to the `NetworkStack` protocol to create a network stack from scratch, Alicerce provides a default stack implementation to handle HTTP requests, represented by the [`URLSessionNetworkStack`][URLSessionNetworkStack] class, which should cover most of the use cases. Internally, this stack is backed by an URLSession.


### Setup

First, start with a network stack, the centerpiece of your network layer. For HTTP networking, it's simple as initializing an `URLSessionNetworkStack`. You need to inject a session into it before starting making any requests – not doing will result in a _fatal error_.

```swift
import Alicerce

let network = Network.URLSessionNetworkStack()

network.session = URLSession(configuration: .default, delegate: network, delegateQueue: nil)
```

> Note that the delegate assigned to the session must be the network stack itself. A session without a delegate or a delegate that is anything but the stack itself results in a _fatal error_.
>
> _To preserve dependency injection, and since a session's delegate is only defined on its initialization, the session must be injected via a property._

Second, you need to create your implementation of a resource. The following example uses Swift Codable to parse and serialize the models.

```swift
enum APIError: Error {
    case generic(message: String)
}

struct RESTResource<T: Codable>: StaticNetworkResource {

    typealias Remote = Data
    typealias Local = T
    typealias Error = APIError

    static var empty: Data { return Data() }

    let parse: (Data) throws -> T = { return try JSONDecoder().decode(T.self, from: $0) }
    let serialize: (T) throws -> Data = { return try JSONEncoder().encode($0) }
    let errorParser: (Data) -> APIError? = { _ in return .generic(message: "oops") }

    let url: URL
    let method: HTTP.Method
    let headers: HTTP.Headers?
    let query: HTTP.Query?
    let body: Data?

    init(url: URL,
         method: HTTP.Method = .GET,
         headers: HTTP.Headers? = nil,
         query: HTTP.Query? = nil,
         body: Data? = nil) {

        self.url = url
        self.method = method
        self.headers = headers
        self.query = query
        self.body = body
    }
}
```


### Making a request

```swift
struct Model: Codable {
    // ...
}

let resource = RESTResource<Model>(url: URL(string: "http://www.api.com")!)

network.fetch(resource: resource) { response in

    do {
        let model = try response()
        // Valid response
    } catch let Network.Error.http(code, apiError as APIError) {
        // API error
    } catch let error as Network.Error {
        // Network error
    } catch {

    }
}
```

[Network]: ../Sources/Network/Network.swift
[NetworkStack]: ../Sources/Network/NetworkStack.swift
[Network.Configuration]: ../Sources/Network/Network.swift#L30
[AuthenticationChallengeHandler]: ../Sources/Network/AuthenticationChallengeHandler.swift
[NetworkAuthenticator]: ../Sources/Network/NetworkAuthenticator.swift
[RequestInterceptor]: ../Sources/Network/RequestInterceptor.swift
[NetworkResource]: ../Sources/Resource/NetworkResource.swift
[Resource]: ../Sources/Resource/Resource.swift
[RelativeNetworkResource]: ../Sources/Resource/NetworkResource.swift#L18
[StaticNetworkResource]: ../Sources/Resource/NetworkResource.swift#L49
[Network.Error]: ../Sources/Network/Network.swift#L20
[URLSessionNetworkStack]: ../Sources/Network/URLSessionNetworkStack.swift
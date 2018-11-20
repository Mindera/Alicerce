//: [Previous](@previous)

import Alicerce
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

// Network Stack

let network = Network.URLSessionNetworkStack()

network.session = URLSession(configuration: .default,
                             delegate: network,
                             delegateQueue: nil)

// API Errors

enum APIError: Error, Decodable {
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

// REST Resource

struct RESTResource<T: Codable>: StaticNetworkResource {

    typealias Remote = Data
    typealias Local = T
    typealias Error = APIError

    static var empty: Data { return Data() }

    let parse: (Data) throws -> T = { try JSONDecoder().decode(T.self, from: $0) }
    let serialize: (T) throws -> Data = { try JSONEncoder().encode($0) }
    let errorParser: (Data) -> APIError? = { try? JSONDecoder().decode(APIError.self, from: $0) }

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

// Model

struct Model: Codable {
    // ...
}

// Request

let resource = RESTResource<Model>(url: URL(string: "http://localhost/")!)

network.fetch(resource: resource) { result in
    switch result {
    case let .success(data):
        data
    case let .failure(.http(code, apiError as APIError)):
        (code, apiError)
    case let .failure(error):
        error
    }
}

//: [Next](@next)

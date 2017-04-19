//
//  URLSessionNetworkStack.swift
//  Alicerce
//
//  Created by Luís Afonso on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public extension Network {

    final class URLSessionNetworkStack: NetworkStack {

        private typealias URLSessionDataTaskClosure = (Data?, URLResponse?, Swift.Error?) -> Void

        private let baseURL: URL
        private let session: URLSession

        init(baseURL: URL, session: URLSession) {
            self.baseURL = baseURL
            self.session = session
        }

        convenience init(configuration: Network.Configuration) {
            let urlSession = URLSession(configuration: configuration.sessionConfiguration,
                                        delegate: nil,
                                        delegateQueue: configuration.delegateQueue)

            self.init(baseURL: configuration.baseURL, session: urlSession)
        }

        public func fetch<R: NetworkResource>(resource: R, _ completion: @escaping Network.CompletionClosure) {
            let request = resource.toRequest(withBaseURL: baseURL)

            session.dataTask(with: request, completionHandler: handleHTTPResponse(with: completion))
            .resume()
        }

        // MARK: - Private Methods

        private func handleHTTPResponse(with completion: @escaping Network.CompletionClosure) -> URLSessionDataTaskClosure {
            return { data, response, error in
                if let error = error {
                    return completion { throw Network.Error.url(error) }
                }

                guard let urlResponse = response as? HTTPURLResponse else {
                    return completion { throw Network.Error.badResponse }
                }

                let httpStatusCode = HTTP.StatusCode(urlResponse.statusCode)

                guard case .success = httpStatusCode else {
                    return completion { throw Network.Error.http(code: httpStatusCode, description: nil) }
                }

                guard let data = data else {
                    return completion { throw Network.Error.noData }
                }
                
                completion { data }
            }
        }
    }
}

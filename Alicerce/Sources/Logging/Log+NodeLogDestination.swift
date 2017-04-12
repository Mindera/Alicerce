//
//  Log+NodeLogDestination.swift
//  Alicerce
//
//  Created by Meik Schutz on 07/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public extension Log {

    public class NodeLogDestination : LogDestination {

        public struct Errors: Error {
            enum ErrorKind {
                case httpError
            }

            let kind: ErrorKind
            let httpStatus: Int
        }

        private static let dispatchQueueLabel = "com.mindera.Alicerce.NodeLogDestination"
        private static let defaultRequestTimeout: TimeInterval = 0

        public private(set) var dispatchQueue: DispatchQueue
        public private(set) var minLevel: Level
        public private(set) var formatter: LogItemFormatter

        private let serverURL: URL
        private let urlSession: URLSession
        private let requestTimeout: TimeInterval

        //MARK:- lifecycle

        public init(serverURL: URL,
                    minLevel: Level = Log.Level.error,
                    formatter: LogItemFormatter = Log.StringLogItemFormatter(),
                    urlSession: URLSession = URLSession.shared,
                    dispatchQueue: DispatchQueue = DispatchQueue(label: NodeLogDestination.dispatchQueueLabel),
                    requestTimeout: TimeInterval = NodeLogDestination.defaultRequestTimeout) {

            self.serverURL = serverURL
            self.minLevel = minLevel
            self.formatter = formatter
            self.urlSession = urlSession
            self.dispatchQueue = dispatchQueue
            self.requestTimeout = requestTimeout
        }

        //MARK:- public methods

        public func write(item: Item, completion: @escaping (LogDestination, Log.Item, Error?) -> Void) {
            dispatchQueue.async { [weak self] in
                guard let strongSelf = self else { return }

                var reportedError: Error?
                defer { completion(strongSelf, item, reportedError) }

                let formattedItem = strongSelf.formatter.format(logItem: item)
                if let payloadData = formattedItem.data(using: .utf8) {
                    strongSelf.send(payload: payloadData) { error in
                        completion(strongSelf, item, error)
                    }
                }
            }
        }

        //MARK:- private methods

        private func send(payload: Data, completion: @escaping (_ error: Error?) -> Void) {

            var request = URLRequest(url: serverURL,
                                     cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                     timeoutInterval: requestTimeout)

            // setup the request's method and headers

            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")

            // setup the request's body

            request.httpBody = payload

            // send request async to server on destination queue

            let task = urlSession.dataTask(with: request) { _, response, error in
                var reportedError: Error? = error
                defer { completion(reportedError) }

                if let error = error {
                    print("Error sending log item to the server \(self.serverURL) with error \(error.localizedDescription)")
                }
                else {
                    guard let response = response as? HTTPURLResponse,
                        response.statusCode != 200 else { return }

                    reportedError = Errors(kind: .httpError, httpStatus: response.statusCode)
                    print("Error sending log item to the server \(self.serverURL) with HTTP status \(response.statusCode)")
                }
            }
            
            task.resume()
        }
    }
}

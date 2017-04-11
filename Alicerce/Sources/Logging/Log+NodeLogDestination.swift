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

        private static let dispatchQueueLabel = "com.mindera.Alicerce.NodeLogDestination"
        private static let defaultRequestTimeout: TimeInterval = 0

        public private(set) var dispatchQueue: DispatchQueue
        public var minLevel = Log.Level.error
        public var formatter: LogItemFormatter = Log.StringLogItemFormatter()

        public var logItemsSent = 0

        private let serverURL: URL
        private let urlSession: URLSession
        private let requestTimeout: TimeInterval

        //MARK:- lifecycle

        public init(serverURL: URL,
                    urlSession: URLSession = URLSession.shared,
                    dispatchQueue: DispatchQueue = DispatchQueue(label: NodeLogDestination.dispatchQueueLabel),
                    requestTimeout: TimeInterval = NodeLogDestination.defaultRequestTimeout) {

            self.serverURL = serverURL
            self.urlSession = urlSession
            self.dispatchQueue = dispatchQueue
            self.requestTimeout = requestTimeout
        }

        //MARK:- public methods

        public func write(item: Item) {
            weak var weakSelf = self
            dispatchQueue.sync {
                let formattedItem = formatter.format(logItem: item)
                if let payloadData = formattedItem.data(using: .utf8) {
                    send(payload: payloadData) { success in
                        guard let strongSelf = weakSelf else { return }
                        if success { strongSelf.logItemsSent += 1 }
                    }
                }
            }
        }

        //MARK:- private methods

        private func send(payload: Data, completion: @escaping (_ success: Bool) -> Void) {

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
                var result = false
                defer { completion(result) }

                if let error = error {
                    print("Error sending log item to the server \(self.serverURL) with error \(error.localizedDescription)")
                }
                else {
                    if let response = response as? HTTPURLResponse {
                        if response.statusCode == 200 {
                            result = true
                        }
                        else {
                            print("Error sending log item to the server \(self.serverURL) with HTTP status \(response.statusCode)")
                        }
                    }
                }
            }
            
            task.resume()
        }
    }
}

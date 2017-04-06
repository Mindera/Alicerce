//
//  NodeProvider.swift
//  Alicerce
//
//  Created by Meik Schutz on 06/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public final class NodeProvider {

    private static let dispatchQueueLabel = "Alicerce-Log"
    private static let defaultRequestTimeout: TimeInterval = 0

    fileprivate let serverURL: URL
    fileprivate let operationQueue = OperationQueue()
    fileprivate let requestTimeout: TimeInterval

    public var minLevel: Log.Level = .error
    public var formatter: LogItemFormatter = LogItemStringFormatter()

    public var logItemsSent: Int = 0

    //MARK:- lifecycle

    public init(serverURL: URL,
                dispatchQueue: DispatchQueue = DispatchQueue(label: NodeProvider.dispatchQueueLabel),
                requestTimeout: TimeInterval = NodeProvider.defaultRequestTimeout) {
        self.serverURL = serverURL
        self.requestTimeout = requestTimeout
        self.operationQueue.underlyingQueue = dispatchQueue
    }

    //MARK:- private methods

    internal func send(payload: Data, completion: @escaping (_ success: Bool) -> Void) {

        let session = URLSession(configuration: URLSessionConfiguration.default,
                                 delegate: nil, delegateQueue: operationQueue)

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

        let task = session.dataTask(with: request) { _, response, error in
            var result = false
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
            return completion(result)
        }

        task.resume()
    }
}

//MARK:- LogProvider

extension NodeProvider: LogProvider {

    public func providerInstanceId() -> String {
        return "\(type(of: self))"
    }

    public func write(item: LogItem) {
        let formattedItem = formatter.format(logItem: item)
        if let payloadData = formattedItem.data(using: .utf8) {
            send(payload: payloadData) { (success) in
                if success { self.logItemsSent += 1 }
            }
        }
    }
}

//
//  NetworkPersistableStore.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 18/01/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import Foundation

public class NetworkPersistableStore<Network: NetworkStack, Persistence: PersistenceStack>: NetworkStore
where Network.Remote == Data, Persistence.Remote == Data {

    public typealias Remote = Data
    public typealias E = Error

    private let networkStack: Network
    private let persistenceStack: Persistence
    private let performanceMetrics: ResourceParsePerformanceMetrics?

    public init(networkStack: Network,
                persistenceStack: Persistence,
                performanceMetrics: ResourceParsePerformanceMetrics?) {
        self.networkStack = networkStack
        self.persistenceStack = persistenceStack
        self.performanceMetrics = performanceMetrics
    }

    @discardableResult
    public func fetch<R>(resource: R, completion: @escaping NetworkStoreCompletionClosure<R.Local, E>) -> Cancelable
    where R: NetworkResource & PersistableResource & StrategyFetchResource, R.Remote == Remote {

        switch resource.strategy {
        case .networkThenPersistence: return fetchNetworkFirst(resource: resource, completion: completion)
        case .persistenceThenNetwork: return fetchPersistenceFirst(resource: resource, completion: completion)
        }
    }

    private func fetchNetworkFirst<R>(resource: R, completion: @escaping NetworkStoreCompletionClosure<R.Local, E>)
    -> Cancelable
    where R: NetworkResource & PersistableResource, R.Remote == Data {

        let cancelable = NetworkCancelable()

        // 1st - Try to fetch from the Network
        cancelable.networkCancelable = getNetworkData(resource) { [weak self] (data, error) in

            // Check if it's cancelled
            guard cancelable.isCancelled == false else { return completion(nil, Error.cancelled) }

            // The system failed to retrieve the data from the network,
            // so we should check if the data is already on disk
            if let error = error {

                // 2nd - Fetch data from the Persistence
                self?.getPersistedData(for: resource) { [weak self] (data) in

                    // If we don't have on disk return the network error
                    guard let data = data else { return completion(nil, error) }

                    // parse the new value from the data
                    self?.process(data,
                                  fromCache: true,
                                  resource: resource,
                                  cancelable: cancelable,
                                  completion: completion)
                }

            } else if let data = data {

                // parse the new value from the data
                self?.process(data,
                              fromCache: false,
                              resource: resource,
                              cancelable: cancelable,
                              completion: completion)

            } else {

                fatalError("💥 Both data and error are nil, this should not happen.")
            }
        }

        return cancelable
    }

    @discardableResult
    private func fetchPersistenceFirst<R>(resource: R, completion: @escaping NetworkStoreCompletionClosure<R.Local, E>)
    -> Cancelable
    where R: NetworkResource & PersistableResource, R.Remote == Data {

            let cancelable = NetworkCancelable()

            // 1st - Fetch data from the Persistence
            getPersistedData(for: resource) { [weak self] (data) in

                // If we have data we don't need to go to the network
                if let data = data {

                    // parse the new value from the data
                    self?.process(data,
                                  fromCache: true,
                                  resource: resource,
                                  cancelable: cancelable,
                                  completion: completion)

                } else {

                    // 2nd - Try to fetch Data from Network
                    cancelable.networkCancelable = self?.getNetworkData(resource) { data, error in

                        // Check if it's cancelled
                        guard cancelable.isCancelled == false else { return completion(nil, Error.cancelled) }

                        if let error = error {

                            return completion(nil, error)

                        } else if let data = data {

                            // parse the new value from the data
                            self?.process(data,
                                          fromCache: false,
                                          resource: resource,
                                          cancelable: cancelable,
                                          completion: completion)
                        }
                    }
                }
            }

            return cancelable
    }

    // MARK: Processing Methods

    private func process<R>(_ data: Data,
                            fromCache: Bool,
                            resource: R,
                            cancelable: NetworkCancelable,
                            completion: @escaping NetworkStoreCompletionClosure<R.Local, E>)
    where R: NetworkResource & PersistableResource, R.Remote == Data {

        do {
            // Check if it's cancelled
            guard cancelable.isCancelled == false else { return completion(nil, Error.cancelled) }

            // parse the new value from the data
            let value = try parse(data: data, for: resource)

            // Check if it's cancelled
            guard cancelable.isCancelled == false else { return completion(nil, Error.cancelled) }

            // update persistence with new value
            if !fromCache {
                self.persist(data, for: resource)
            }

            completion(fromCache ? .persistence(value) : .network(value), nil)

        } catch let error as Parse.Error {
            completion(nil, Error.parse(error))
        } catch {
            completion(nil, Error.other(error))
        }
    }

    // MARK: Network Methods

    private func getNetworkData<R>(_ resource: R, completion: @escaping (Data?, Error?) -> Void)
    -> Cancelable
    where R: NetworkResource & PersistableResource, R.Remote == Data {

        return networkStack.fetch(resource: resource) {
            (inner: () throws -> Data) -> Void in
            do {
                let data = try inner()

                completion(data, nil)

            } catch let Alicerce.Network.Error.url(error as NSError) where error.domain == NSURLErrorDomain
                && error.code == NSURLErrorCancelled {
                    completion(nil, Error.cancelled)
            } catch let error as Alicerce.Network.Error {
                completion(nil, Error.network(error))
            } catch {
                completion(nil, Error.other(error))
            }
        }
    }

    // MARK: Persistence Methods

    private func getPersistedData<R: PersistableResource>(for resource: R, completion: @escaping (Data?) -> Void) {

        persistenceStack.object(for: resource.persistenceKey) { (inner: () throws -> Data) -> Void in
            do {
                let data = try inner()
                return completion(data)
            } catch Alicerce.Persistence.Error.noObjectForKey {
                // cache/persistence miss
            } catch {
                print("⚠️: Failed to get persisted value for resource \"\(resource)\"! Error: \(error). Fetching...")
            }
            completion(nil)
        }
    }

    private func persist<R: PersistableResource>(_ data: Data, for resource: R) {

        persistenceStack.setObject(data, for: resource.persistenceKey) { (inner: () throws -> Void) -> Void in
            do {
                try inner()
            } catch {
                print("⚠️: Failed to persist value for resource \"\(resource)\"! Error:\(error)")
            }
        }
    }

    private func parse<R: NetworkResource & PersistableResource>(data: Data, for resource: R) throws -> R.Local
    where R.Remote == Data {

        let metricsIdentifier = performanceMetrics?.parseIdentifier(for: resource, payload: "\(data.endIndex)") ?? ""

        performanceMetrics?.metrics.begin(with: metricsIdentifier)

        let value = try resource.parse(data)

        performanceMetrics?.metrics.end(with: metricsIdentifier)

        return value
    }
}

extension NetworkPersistableStore {
    public enum Error: Swift.Error {
        case network(Alicerce.Network.Error)
        case parse(Parse.Error)
        case persistence(Alicerce.Persistence.Error)
        case cancelled
        case other(Swift.Error)
    }

    final class NetworkCancelable: Cancelable {

        fileprivate var networkCancelable: Cancelable?
        fileprivate var isCancelled: Bool = false

        public func cancel() {
            isCancelled = true
            networkCancelable?.cancel()
        }
    }
}

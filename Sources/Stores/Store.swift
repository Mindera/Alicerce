//
//  Store.swift
//  Alicerce
//
//  Created by Luís Afonso on 06/12/2016.
//  Copyright © 2016 Mindera. All rights reserved.
//

import Foundation

public enum StoreError: Error {
    case network(Network.Error)
    case parse(Parse.Error)
    case persistence(Persistence.Error)
    case cancelled
    case other(Swift.Error)
}

public typealias StoreCompletionClosure<T> = ((_ value: T?, _ error: StoreError?, _ fromCache: Bool) -> ())

public protocol Store: class {
    associatedtype T
    associatedtype P: PersistenceStack

    var networkStack: NetworkStack { get }
    var persistenceStack: P { get }

    init(networkStack: NetworkStack, persistenceStack: P)
}

private final class StoreCancelable: Cancelable {

    fileprivate var networkCancelable: Cancelable?
    fileprivate var isCancelled: Bool = false

    public func cancel() {
        isCancelled = true
        networkCancelable?.cancel()
    }
}

public extension Store {

    @discardableResult
    func fetch<Resource: NetworkResource & PersistableResource & StrategyFetchResource>(resource: Resource,
                                                                                        _ completion: @escaping StoreCompletionClosure<T>)
    -> Cancelable
    where Resource.T == T {

        switch resource.strategy {
        case .networkThenPersistence: return fetchNetworkFirst(resource: resource, completion)
        case .persistenceThenNetwork: return fetchPersistenceFirst(resource: resource, completion)
        }
    }

    @discardableResult
    private func fetchNetworkFirst<Resource: NetworkResource & PersistableResource>(resource: Resource,
                                                                                    _ completion: @escaping StoreCompletionClosure<T>)
    -> Cancelable
    where Resource.T == T {

        let cancelable = StoreCancelable()

        // 1st - Try to fetch from the Network
        cancelable.networkCancelable = getNetworkData(resource) { (data, error) in

            // Check if it's cancelled
            guard cancelable.isCancelled == false else { return completion(nil, .cancelled, false) }

            // The system failed to retrieve the data from the network, so we should check if the data is already on disk
            if let error = error {

                // 2nd - Fetch data from the Persistence
                self.getPersistedData(for: resource) { (data) in

                    // If we don't have on disk return the network error
                    guard let data = data else { return completion(nil, error, false) }

                    // parse the new value from the data
                    self.process(data, fromCache: true, resource: resource, cancelable: cancelable, completion)
                }

            } else if let data = data {

                // parse the new value from the data
                self.process(data, fromCache: false, resource: resource, cancelable: cancelable, completion)

            } else {

                fatalError("💥 Both data and error are nil, this should not happen.")
            }
        }

        return cancelable
    }

    @discardableResult
    private func fetchPersistenceFirst<Resource: NetworkResource & PersistableResource>(resource: Resource,
                                                                                        _ completion: @escaping StoreCompletionClosure<T>)
    -> Cancelable
    where Resource.T == T {

        let cancelable = StoreCancelable()

        // 1st - Fetch data from the Persistence
        self.getPersistedData(for: resource) { (data) in

            // If we have data we don't need to go to the network
            if let data = data {

                // parse the new value from the data
                self.process(data, fromCache: true, resource: resource, cancelable: cancelable, completion)

            } else {

                // 2nd - Try to fetch Data from Network
                cancelable.networkCancelable = self.getNetworkData(resource) { (data, error) in

                    // Check if it's cancelled
                    guard cancelable.isCancelled == false else { return completion(nil, .cancelled, false) }

                    // If we got an error we need to check if we have the data on disk
                    if let error = error {

                        return completion(nil, error, false)

                    } else if let data = data {

                        // parse the new value from the data
                        self.process(data, fromCache: false, resource: resource, cancelable: cancelable, completion)
                    }
                }
            }
        }

        return cancelable
    }

    // MARK: Processing Methods

    private func process<Resource: NetworkResource & PersistableResource>(_ data: Data,
                                                                          fromCache: Bool,
                                                                          resource: Resource,
                                                                          cancelable: StoreCancelable,
                                                                          _ completion: @escaping StoreCompletionClosure<T>)
    where Resource.T == T {

        do {
            // Check if it's cancelled
            guard cancelable.isCancelled == false else { return completion(nil, .cancelled, false) }

            // parse the new value from the data
            let value = try resource.parser(data)

            // Check if it's cancelled
            guard cancelable.isCancelled == false else { return completion(nil, .cancelled, false) }

            // update persistence with new value
            if !fromCache {
                persist(data, for: resource)
            }

            completion(value, nil, fromCache)

        } catch let error as Parse.Error {
            completion(nil, .parse(error), false)
        } catch {
            completion(nil, .other(error), false)
        }
    }

    // MARK: Network Methods

    private func getNetworkData<Resource: NetworkResource & PersistableResource>(_ resource: Resource,
                                                                                 completion: @escaping (Data?, StoreError?) -> ())
    -> Cancelable {

        return networkStack.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
            do {
                let data = try inner()

                completion(data, nil)

            } catch let Network.Error.url(error as NSError) where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                    completion(nil, .cancelled)
            } catch let error as Network.Error {
                completion(nil, .network(error))
            } catch {
                completion(nil, .other(error))
            }
        }
    }

    // MARK: Persistence Methods

    private func getPersistedData<Resource: PersistableResource>(for resource: Resource,
                                                                 completion: @escaping (Data?) -> ()) {
        persistenceStack.object(for: resource.persistenceKey) { (inner: () throws -> Data) -> Void in
            do {
                let data = try inner()
                return completion(data)
            } catch Persistence.Error.noObjectForKey {
                // cache/persistence miss
            } catch {
                print("⚠️: Failed to get persisted value for resource \"\(resource)\"! Error: \(error). Fetching...")
            }
            completion(nil)
        }
    }

    private func persist<Resource: PersistableResource>(_ data: Data, for resource: Resource) {
        persistenceStack.setObject(data, for: resource.persistenceKey) { (inner: () throws -> Void) -> Void in
            do {
                try inner()
            } catch {
                print("⚠️: Failed to persist value for resource \"\(resource)\"! Error:\(error)")
            }
        }
    }
}

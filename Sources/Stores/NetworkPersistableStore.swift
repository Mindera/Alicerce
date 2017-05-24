//
//  NetworkPersistableStore.swift
//  Alicerce
//
//  Created by Luís Portela on 23/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public class NetworkPersistableStore: Store {

    private let networkStack: NetworkStack
    private let persistenceStack: PersistenceStack

    public init(networkStack: NetworkStack, persistenceStack: PersistenceStack) {
        self.networkStack = networkStack
        self.persistenceStack = persistenceStack
    }

    @discardableResult
    public func fetch<Resource: NetworkResource & PersistableResource>(resource: Resource,
                                                                _ completion: @escaping StoreCompletionClosure<Resource.T>)
    -> Alicerce.Cancelable
    where Resource.F == Data {
        let cancelable = Cancelable()

        // fetch a fresh value from the network if no hit
        func fetch(resource: Resource) {
            cancelable.networkCancelable = networkStack.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
                do {
                    let data = try inner()

                    guard cancelable.isCancelled == false else { return completion(nil, Error.cancelled, false) }

                    // parse the new value from the data
                    let value = try resource.parser(data)

                    guard cancelable.isCancelled == false else { return completion(nil, Error.cancelled, false) }

                    // update persistence with new value
                    self.persist(data, for: resource)

                    completion(value, nil, false)
                } catch let Network.Error.url(error as NSError) where error.domain == NSURLErrorDomain
                    && error.code == NSURLErrorCancelled {
                        completion(nil, Error.cancelled, false)
                } catch let error as Network.Error {
                    completion(nil, Error.network(error), false)
                } catch let error as Parse.Error {
                    completion(nil, Error.parse(error), false)
                } catch {
                    completion(nil, Error.other(error), false)
                }
            }
        }

        // check persistence to see if we have a hit and return immediately if so
        getPersistedData(for: resource) {
            guard let data = $0 else {
                return fetch(resource: resource)
            }

            do {
                let value = try resource.parser(data)
                completion(value, nil, true)
            } catch {
                // try to fetch fresh data if parsing of existent data failed
                // TODO: remove from persistence?
                return fetch(resource: resource)
            }
        }

        return cancelable
    }

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

extension NetworkPersistableStore {
    public enum Error: StoreError {
        case network(Network.Error)
        case parse(Parse.Error)
        case persistence(Persistence.Error)
        case cancelled
        case other(Swift.Error)
    }

    final class Cancelable: Alicerce.Cancelable {

        fileprivate var networkCancelable: Alicerce.Cancelable?
        fileprivate var isCancelled: Bool = false

        public func cancel() {
            isCancelled = true
            networkCancelable?.cancel()
        }
    }
}

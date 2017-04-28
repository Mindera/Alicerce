//
//  Store.swift
//  Alicerce
//
//  Created by Luís Afonso on 06/12/2016.
//  Copyright © 2016 Mindera. All rights reserved.
//

import Foundation

enum StoreError: Error {
    case network(Network.Error)
    case parse(Parse.Error)
    case persistence(Persistence.Error)
    case other(Swift.Error)
}

typealias StoreCompletionClosure<T> = ((_ value: T?, _ error: StoreError?, _ fromCache: Bool) -> ())

protocol Store {
    associatedtype T
    associatedtype P: PersistenceStack

    var networkStack: NetworkStack { get }
    var persistenceStack: P { get }

    init(networkStack: NetworkStack, persistenceStack: P)
}

extension Store {

    func fetch<Resource: NetworkResource & PersistableResource>(resource: Resource,
                                                                _ completion: @escaping StoreCompletionClosure<T>)
    where Resource.T == T {

        // fetch a fresh value from the network if no hit
        func fetch(resource: Resource) {
            networkStack.fetch(resource: resource) { (inner: () throws -> Data) -> Void in
                do {
                    let data = try inner()
                    let value = try resource.parser(data)

                    // update persistence with new value
                    self.persist(data, for: resource)

                    completion(value, nil, false)
                } catch let error as Network.Error {
                    completion(nil, .network(error), false)
                } catch let error as Parse.Error {
                    completion(nil, .parse(error), false)
                } catch {
                    completion(nil, .other(error), false)
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

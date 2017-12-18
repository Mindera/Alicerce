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
    var metricsConfiguration: StoreMetricsConfiguration<T>? { get }

    init(networkStack: NetworkStack, persistenceStack: P, metricsConfiguration: StoreMetricsConfiguration<T>?)
}

private final class StoreCancelable: Cancelable {

    fileprivate var networkCancelable: Cancelable?
    fileprivate var isCancelled: Bool = false

    public func cancel() {
        isCancelled = true
        networkCancelable?.cancel()
    }
}

public struct StoreMetricsConfiguration<T> {
    let metrics: PerformanceMetrics
    let identifier: (T.Type, Data) -> String

    public init(metrics: PerformanceMetrics,
                identifier: @escaping (T.Type, Data) -> String = { "Parse of \(T.self) with size: \($1.endIndex)" }) {
        self.metrics = metrics
        self.identifier = identifier
    }
}

public extension Store {

    @discardableResult
    func fetch<Resource: NetworkResource & PersistableResource>(resource: Resource,
                                                                _ completion: @escaping StoreCompletionClosure<T>)
    -> Cancelable
    where Resource.T == T {
        let cancelable = StoreCancelable()

        // fetch a fresh value from the network if no hit
        func fetch(resource: Resource) {
            cancelable.networkCancelable = networkStack.fetch(resource: resource) {
                [weak self] (inner: () throws -> Data) -> Void in
                do {
                    let data = try inner()

                    guard cancelable.isCancelled == false else { return completion(nil, .cancelled, false) }

                    // parse the new value from the data
                    let value = try self?.parse(data: data, for: resource)

                    guard cancelable.isCancelled == false else { return completion(nil, .cancelled, false) }

                    // update persistence with new value
                    self?.persist(data, for: resource)

                    completion(value, nil, false)
                } catch let Network.Error.url(error as NSError) where error.domain == NSURLErrorDomain
                    && error.code == NSURLErrorCancelled {
                        completion(nil, .cancelled, false)
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
        getPersistedData(for: resource) { [weak self] in
            guard let data = $0 else {
                return fetch(resource: resource)
            }

            do {
                let value = try self?.parse(data: data, for: resource)

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

    private func parse<Resource: NetworkResource & PersistableResource>(data: Data, for resource: Resource) throws
    -> Resource.T {
        let metricsIdentifier = metricsConfiguration?.identifier(T.self, data) ?? ""
        metricsConfiguration?.metrics.begin(with: metricsIdentifier)

        let value = try resource.parser(data)

        metricsConfiguration?.metrics.end(with: metricsIdentifier)

        return value
    }
}


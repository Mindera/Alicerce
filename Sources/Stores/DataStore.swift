//
//  DataStore.swift
//  Alicerce
//
//  Created by Luís Afonso on 27/04/2017.
//  Copyright © 2016 Mindera. All rights reserved.
//

import Foundation

public final class DataStore<U, P: PersistenceStack>: Store {
    public typealias T = U
    
    public let networkStack: NetworkStack
    public let persistenceStack: P
    public let metricsConfiguration: StoreMetricsConfiguration<T>?
    
    public init(networkStack: NetworkStack, persistenceStack: P, metricsConfiguration: StoreMetricsConfiguration<T>?) {
        self.networkStack = networkStack
        self.persistenceStack = persistenceStack
        self.metricsConfiguration = metricsConfiguration
    }
}

//
//  DataStore.swift
//  Alicerce
//
//  Created by Luís Afonso on 27/04/2017.
//  Copyright © 2016 Mindera. All rights reserved.
//

import Foundation

final class DataStore<U, P: PersistenceStack>: Store {
    typealias T = U
    
    let networkStack: NetworkStack
    let persistenceStack: P
    
    init(networkStack: NetworkStack, persistenceStack: P) {
        self.networkStack = networkStack
        self.persistenceStack = persistenceStack
    }
}

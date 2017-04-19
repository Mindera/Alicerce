//
//  NSPersistentStoreDescription+CoreDataStack.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 04/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import CoreData

@available(iOS 10.0, *)
public extension NSPersistentStoreDescription {

    convenience init(storeType: CoreDataStackStoreType) {
        switch storeType {
        case .inMemory:
            self.init()
            self.type = NSInMemoryStoreType
        case let .sqLite(url):
            self.init(url: url)
            self.type = NSSQLiteStoreType
        }
    }
}

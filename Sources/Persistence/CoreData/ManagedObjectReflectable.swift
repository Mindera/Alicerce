//
//  ManagedObjectReflectable.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 03/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import CoreData

public protocol ManagedObjectReflectable {
    associatedtype ManagedObject: NSManagedObject

    func reflect(to managedObject: ManagedObject)

    init(managedObject: ManagedObject)

    static func exclude(_ lhs: [ManagedObject], from rhs: [Self]) -> [Self]
}

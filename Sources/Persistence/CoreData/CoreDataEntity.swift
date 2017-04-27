//
//  CoreDataEntity.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 03/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import CoreData

public protocol CoreDataEntity: class, NSFetchRequestResult {
    static var entityName: String { get }
}

public extension CoreDataEntity where Self: NSManagedObject {

    static var entityName: String {
        return "\(Self.self)"
    }

    @available(iOS, obsoleted: 10, message: "use `NSManagedObject`'s `fetchRequest()` instead")
    static func anyFetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest(entityName: entityName)
    }

    static func fetchRequest() -> NSFetchRequest<Self> {
        return NSFetchRequest(entityName: entityName)
    }

    static func fetchRequest() -> NSFetchRequest<NSManagedObjectID> {
        return NSFetchRequest(entityName: entityName)
    }

    static func fetchRequest() -> NSFetchRequest<NSDictionary> {
        return NSFetchRequest(entityName: entityName)
    }

    static func fetchRequest() -> NSFetchRequest<NSNumber> {
        return NSFetchRequest(entityName: entityName)
    }

    static func batchUpdateRequest() -> NSBatchUpdateRequest {
        if #available(iOS 10.0, *) {
            return NSBatchUpdateRequest(entity: entity())
        } else {
            return NSBatchUpdateRequest(entityName: entityName)
        }
    }

    @available(iOS, obsoleted: 10, message: "use `NSManagedObject`'s `init(context:)` instead")
    init(in context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: Self.entityName, in: context)!

        self.init(entity: entity, insertInto: context)
    }
}

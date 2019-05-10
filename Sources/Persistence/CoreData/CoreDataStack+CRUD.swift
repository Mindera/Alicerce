import CoreData

public extension CoreDataStack {

    typealias TransformClosure<Internal, External> = (Internal) throws -> External
    typealias CreateClosure<Internal, External> = (NSManagedObjectContext) throws -> ([Internal], [External])
    typealias UpdateClosure<Internal, External> = (Internal) throws -> External
    typealias FilterAndCreateClosure<Internal, External> =
        ([Internal], NSManagedObjectContext) throws -> ([Internal], [External])

    func exists<Entity: NSManagedObject & CoreDataEntity>(
        _ entity: Entity.Type,
        predicate: NSPredicate,
        contextType: CoreDataStackContextType = .work
    ) throws -> Bool {

        let fetchRequest: NSFetchRequest<NSNumber> = Entity.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1

        let context = self.context(withType: contextType)

        return try context.performThrowingAndWait {
            try context.count(for: fetchRequest) > 0
        }
    }

    func fetch<Internal: NSManagedObject & CoreDataEntity, External>(
        with predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]? = nil,
        fetchLimit: Int = 0,
        objectsAsFaults: Bool = false,
        contextType: CoreDataStackContextType = .work,
        transform: @escaping TransformClosure<Internal, External>
    ) throws -> [External] {

        let fetchRequest: NSFetchRequest<Internal> = Internal.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchLimit = fetchLimit
        fetchRequest.returnsObjectsAsFaults = objectsAsFaults

        let context = self.context(withType: contextType)

        return try context.performThrowingAndWait {
            try context.fetch(fetchRequest).map(transform)
        }
    }

    func findOrCreate<Internal: NSManagedObject & CoreDataEntity, External>(
        with predicate: NSPredicate,
        contextType: CoreDataStackContextType = .work,
        filterExistingAndCreate: @escaping FilterAndCreateClosure<Internal, External>,
        transform: @escaping TransformClosure<Internal, External>
    ) throws -> [External] {

        return try createOrUpdate(with: predicate,
                                  contextType: contextType,
                                  filterUpdatedAndCreate: filterExistingAndCreate,
                                  update: transform)
    }

    func create<Internal: NSManagedObject & CoreDataEntity, External>(
        contextType: CoreDataStackContextType = .work,
        create: @escaping CreateClosure<Internal, External>
    ) throws -> [External] {

        let context = self.context(withType: contextType)
        return try context.performThrowingAndWait {
            let (objects, transforms) = try create(context)

            try context.persistChanges(
                """
                create \([Internal].self):
                    objects: \(objects)
                    transforms: \(transforms)
                """)

            return transforms
        }
    }

    func createOrUpdate<Internal: NSManagedObject & CoreDataEntity, External>(
        with predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]? = nil,
        contextType: CoreDataStackContextType = .work,
        filterUpdatedAndCreate: @escaping FilterAndCreateClosure<Internal, External>,
        update: @escaping UpdateClosure<Internal, External>
    ) throws -> [External] {

        let fetchRequest: NSFetchRequest<Internal> = Internal.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.returnsObjectsAsFaults = false // avoid firing a fault to update the object's properties

        let context = self.context(withType: contextType)

        return try context.performThrowingAndWait {
            let objects = try context.fetch(fetchRequest)

            // filter before updating so we can better compare objects
            // for example, we can use the `Hashable` properties of `ManagedObjectReflectable` and use `Set`'s
            let (createdObjects, created) = try filterUpdatedAndCreate(objects, context)

            assert(createdObjects.count == created.count,
                   "🔥 Inconsistent number of created `Internal`'s and `External`'s on the `filterUpdatedAndCreate`!")

            assert(Set(createdObjects).isDisjoint(with: Set(objects)),
                   "🔥 Updated objects should't be returned on the `filterUpdatedAndCreate` closure!")

            let updated = try objects.map(update)

            try context.persistChanges(
                """
                createOrUpdate \([Internal].self):
                    Updated (objects: \(objects), transforms: \(updated))
                    Created (objects: \(createdObjects), transforms: \(created)
                """)

            return created + updated
        }
    }

    func update<Internal: NSManagedObject & CoreDataEntity, External>(
        with predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]? = nil,
        fetchLimit: Int = 0,
        contextType: CoreDataStackContextType = .work,
        update: @escaping UpdateClosure<Internal, External>
    ) throws -> [External] {

        let fetchRequest: NSFetchRequest<Internal> = Internal.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchLimit = fetchLimit
        fetchRequest.returnsObjectsAsFaults = false // fire a fault to update the object's properties

        let context = self.context(withType: contextType)

        return try context.performThrowingAndWait {
            let objects = try context.fetch(fetchRequest)
            let updated = try objects.map(update)

            try context.persistChanges(
                """
                update \(Internal.self):
                    objects: \(objects)
                    transforms: \(updated)
                """)

            return updated
        }
    }

    func delete<Entity: NSManagedObject & CoreDataEntity>(
        _ entity: Entity.Type, // help the type inferer if `cleanup` is nil
        predicate: NSPredicate,
        fetchLimit: Int = 0,
        contextType: CoreDataStackContextType = .work,
        cleanup: ((Entity) -> Void)? = nil
    ) throws -> Int {

        let context = self.context(withType: contextType)

        return try context.performThrowingAndWait {

            let count: Int

            // NSBatchDeleteRequest is only available on SQLite stores
            if context.isSQLiteStoreBased, cleanup == nil {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Entity.fetchRequest()
                fetchRequest.predicate = predicate
                fetchRequest.fetchLimit = fetchLimit

                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteRequest.resultType = .resultTypeObjectIDs

                guard let fetchResult = try context.execute(deleteRequest) as? NSBatchDeleteResult else {
                    fatalError("💥 Unexpected `NSPersistentStoreResult` subclass!")
                }

                guard let objectIDs = fetchResult.result as? [NSManagedObjectID] else {
                    fatalError("💥 Unexpected or `NSBatchDeleteResult`: \(String(describing: fetchResult.result))!")
                }

                if objectIDs.isEmpty == false {
                    let changes = [NSDeletedObjectsKey  : objectIDs]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                }

                // uncomment this line to have the changes available (and saved) immediately on the context
                // otherwise, the deleted objects will still be visible on the context, but with `isDeleted = true`
                // note however that it will cause most performance benefits of using a batch delete to be lost.
                //objectIDs.forEach { context.delete(context.object(with: $0)) }

                count = objectIDs.count
            } else {
                let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
                fetchRequest.predicate = predicate
                fetchRequest.fetchLimit = fetchLimit
                fetchRequest.returnsObjectsAsFaults = (cleanup != nil)

                let objects = try context.fetch(fetchRequest)
                objects.forEach {
                    cleanup?($0)
                    context.delete($0)
                }

                count = objects.count
            }

            // wait for the parent to ensure that objects are effectively deleted from the database on return
            try context.persistChanges("delete \(Entity.self) matching predicate: \(predicate)", waitForParent: true)

            return count
        }
    }

    func count<Entity: NSManagedObject & CoreDataEntity>(
        _ entity: Entity.Type,
        with predicate: NSPredicate,
        contextType: CoreDataStackContextType = .work
    ) throws -> Int {

        let fetchRequest: NSFetchRequest<NSNumber> = Entity.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.resultType = .countResultType

        let context = self.context(withType: contextType)

        return try context.performThrowingAndWait {
            try context.count(for: fetchRequest)
        }
    }

    func performClosure<Entity: NSManagedObject & CoreDataEntity>(
        _ entity: Entity.Type,
        with predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]? = nil,
        fetchLimit: Int = 0,
        objectsAsFaults: Bool = true,
        contextType: CoreDataStackContextType = .work,
        persistChanges: Bool = false,
        closure: @escaping ([Entity]) -> Void
    ) throws {

        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchLimit = fetchLimit
        fetchRequest.returnsObjectsAsFaults = objectsAsFaults

        let context = self.context(withType: contextType)

        try context.performThrowingAndWait {
            let objects = try context.fetch(fetchRequest)
            closure(objects)

            if persistChanges {
                try context.persistChanges("perform closure on \(Entity.self) matching predicate: \(predicate)")
            }
        }
    }
}

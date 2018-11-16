import CoreData

public extension CoreDataStack {

    func exists<Entity: ManagedObjectReflectable>(_ entity: Entity.Type,
                                                  predicate: NSPredicate,
                                                  contextType: CoreDataStackContextType = .work) throws -> Bool
    where Entity.ManagedObject: CoreDataEntity {

        return try exists(Entity.ManagedObject.self, predicate: predicate, contextType: contextType)
    }

    func fetch<Entity: ManagedObjectReflectable>(with predicate: NSPredicate,
                                                 sortDescriptors: [NSSortDescriptor]? = nil,
                                                 fetchLimit: Int = 0,
                                                 objectsAsFaults: Bool = false,
                                                 contextType: CoreDataStackContextType = .work) throws -> [Entity]
    where Entity.ManagedObject: CoreDataEntity {

        return try fetch(with: predicate,
                         sortDescriptors: sortDescriptors,
                         fetchLimit: fetchLimit,
                         objectsAsFaults: objectsAsFaults,
                         contextType: contextType,
                         transform: Entity.init(managedObject:))
    }

    func findOrCreate<Entity: ManagedObjectReflectable>(
        withPredicate predicate: NSPredicate,
        entities: [Entity],
        contextType: CoreDataStackContextType = .work) throws -> [Entity]
    where Entity.ManagedObject: CoreDataEntity {

        return try findOrCreate(with: predicate,
                                contextType: contextType,
                                filterExistingAndCreate: filterAndCreateClosure(with: entities),
                                transform: Entity.init(managedObject:))
    }

    func create<Entity: ManagedObjectReflectable>(_ entities: [Entity],
                                                  contextType: CoreDataStackContextType = .work) throws
    where Entity.ManagedObject: CoreDataEntity {

        let _: [Entity] = try create(contextType: contextType, create: self.createClosure(with: entities))
    }

    func createOrUpdate<Entity: ManagedObjectReflectable>(with predicate: NSPredicate,
                                                          sortDescriptors: [NSSortDescriptor]? = nil,
                                                          contextType: CoreDataStackContextType = .work,
                                                          entities: [Entity],
                                                          update: @escaping (Entity) -> Entity) throws -> [Entity]
    where Entity.ManagedObject: CoreDataEntity {

        return try createOrUpdate(with: predicate,
                                  sortDescriptors: sortDescriptors,
                                  contextType: contextType,
                                  filterUpdatedAndCreate: filterAndCreateClosure(with: entities),
                                  update: updateClosure(with: update))
    }

    func update<Entity: ManagedObjectReflectable>(with predicate: NSPredicate,
                                                  sortDescriptors: [NSSortDescriptor]? = nil,
                                                  fetchLimit: Int = 0,
                                                  contextType: CoreDataStackContextType = .work,
                                                  _ update: @escaping (Entity) -> Entity) throws -> [Entity]
    where Entity.ManagedObject: CoreDataEntity {

        return try self.update(with: predicate,
                               sortDescriptors: sortDescriptors,
                               fetchLimit: fetchLimit,
                               contextType: contextType,
                               update: updateClosure(with: update))
    }

    func delete<Entity: ManagedObjectReflectable>(_ entity: Entity.Type, // help the type inferer if `cleanup` is nil
                                                  predicate: NSPredicate,
                                                  fetchLimit: Int = 0,
                                                  contextType: CoreDataStackContextType = .work,
                                                  cleanup: ((Entity) -> Void)? = nil) throws -> Int
    where Entity.ManagedObject: CoreDataEntity {

        var reflectCleanup: ((Entity.ManagedObject) -> Void)?
        if let cleanup = cleanup {
            reflectCleanup = { cleanup(Entity(managedObject: $0)) }
        }

        return try delete(Entity.ManagedObject.self,
                          predicate: predicate,
                          fetchLimit: fetchLimit,
                          contextType: contextType,
                          cleanup: reflectCleanup)
    }

    func count<Entity: ManagedObjectReflectable>(_ entity: Entity.Type,
                                                 predicate: NSPredicate,
                                                 contextType: CoreDataStackContextType = .work) throws -> Int
    where Entity.ManagedObject: CoreDataEntity {

        return try count(Entity.ManagedObject.self, predicate: predicate, contextType: contextType)
    }

    // MARK: Closure generation

    fileprivate func createClosure<Entity: ManagedObjectReflectable>(with newEntities: [Entity])
    -> (NSManagedObjectContext) throws -> ([Entity.ManagedObject], [Entity])
    where Entity.ManagedObject: CoreDataEntity {

        return { context in
            let newManagedObjects: [Entity.ManagedObject] = newEntities.map {
                let managedObject = Entity.ManagedObject(in: context)
                $0.reflect(to: managedObject)
                return managedObject
            }

            return (newManagedObjects, newEntities)
        }
    }

    fileprivate func updateClosure<Entity: ManagedObjectReflectable>(with update: @escaping (Entity) -> Entity)
    -> (Entity.ManagedObject) throws -> Entity where Entity.ManagedObject: CoreDataEntity {

        return { managedObject in
            let updated = update(Entity(managedObject: managedObject))
            updated.reflect(to: managedObject)
            return updated
        }
    }

    fileprivate func filterAndCreateClosure<Entity: ManagedObjectReflectable>(with allEntities: [Entity])
    -> ([Entity.ManagedObject], NSManagedObjectContext) throws -> ([Entity.ManagedObject], [Entity])
    where Entity.ManagedObject: CoreDataEntity {

        return { existing, context in
            let newEntities = Entity.exclude(existing, from: allEntities)

            let newManagedObjects: [Entity.ManagedObject] = newEntities.map {
                let managedObject = Entity.ManagedObject(in: context)
                $0.reflect(to: managedObject)
                return managedObject
            }

            return (newManagedObjects, Array(newEntities))
        }
    }
}

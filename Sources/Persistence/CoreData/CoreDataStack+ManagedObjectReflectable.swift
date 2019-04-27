import CoreData

public extension CoreDataStack {

    func exists<Entity: ManagedObjectReflectable>(
        _ entity: Entity.Type,
        predicate: NSPredicate,
        contextType: CoreDataStackContextType = .work
    ) throws -> Bool where Entity.ManagedObject: CoreDataEntity {

        return try exists(Entity.ManagedObject.self, predicate: predicate, contextType: contextType)
    }

    func fetch<Entity: ManagedObjectReflectable>(
        _ entity: Entity.Type,
        with predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]? = nil,
        fetchLimit: Int = 0,
        objectsAsFaults: Bool = false,
        contextType: CoreDataStackContextType = .work
    ) throws -> [Entity] where Entity.ManagedObject: CoreDataEntity {

        return try fetch(with: predicate,
                         sortDescriptors: sortDescriptors,
                         fetchLimit: fetchLimit,
                         objectsAsFaults: objectsAsFaults,
                         contextType: contextType,
                         transform: Entity.init(managedObject:))
    }

    func findOrCreate<Entity: ManagedObjectReflectable>(
        with predicate: NSPredicate,
        entities: [Entity],
        contextType: CoreDataStackContextType = .work
    ) throws -> [Entity] where Entity.ManagedObject: CoreDataEntity {

        return try findOrCreate(with: predicate,
                                contextType: contextType,
                                filterExistingAndCreate: makeFilterAndCreateClosure(with: entities),
                                transform: Entity.init(managedObject:))
    }

    func create<Entity: ManagedObjectReflectable>(
        _ entities: [Entity],
        contextType: CoreDataStackContextType = .work
    ) throws where Entity.ManagedObject: CoreDataEntity {

        let _: [Entity] = try create(contextType: contextType, create: makeCreateClosure(with: entities))
    }

    func createOrUpdate<Entity: ManagedObjectReflectable>(
        with predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]? = nil,
        contextType: CoreDataStackContextType = .work,
        entities: [Entity],
        update: @escaping (Entity) -> Entity
    ) throws -> [Entity] where Entity.ManagedObject: CoreDataEntity {

        return try createOrUpdate(with: predicate,
                                  sortDescriptors: sortDescriptors,
                                  contextType: contextType,
                                  filterUpdatedAndCreate: makeFilterAndCreateClosure(with: entities),
                                  update: makeUpdateClosure(with: update))
    }

    func update<Entity: ManagedObjectReflectable>(
        _ entity: Entity.Type,
        with predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]? = nil,
        fetchLimit: Int = 0,
        contextType: CoreDataStackContextType = .work,
        update: @escaping (Entity) -> Entity
    ) throws -> [Entity] where Entity.ManagedObject: CoreDataEntity {

        return try self.update(with: predicate,
                               sortDescriptors: sortDescriptors,
                               fetchLimit: fetchLimit,
                               contextType: contextType,
                               update: makeUpdateClosure(with: update))
    }

    func delete<Entity: ManagedObjectReflectable>(
        _ entity: Entity.Type, // help the type inferer if `cleanup` is nil
        predicate: NSPredicate,
        fetchLimit: Int = 0,
        contextType: CoreDataStackContextType = .work,
        cleanup: ((Entity) -> Void)? = nil
    ) throws -> Int where Entity.ManagedObject: CoreDataEntity {

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

    func count<Entity: ManagedObjectReflectable>(
        _ entity: Entity.Type,
        with predicate: NSPredicate,
        contextType: CoreDataStackContextType = .work
    ) throws -> Int where Entity.ManagedObject: CoreDataEntity {

        return try count(Entity.ManagedObject.self, with: predicate, contextType: contextType)
    }

    // MARK: Closure generation

    private func makeCreateClosure<Entity: ManagedObjectReflectable>(
        with newEntities: [Entity]
    ) -> CreateClosure<Entity.ManagedObject, Entity> where Entity.ManagedObject: CoreDataEntity {

        return { context in
            let newManagedObjects: [Entity.ManagedObject] = newEntities.map {
                let managedObject = Entity.ManagedObject(context: context)
                $0.reflect(to: managedObject)
                return managedObject
            }

            return (newManagedObjects, newEntities)
        }
    }

    private func makeUpdateClosure<Entity: ManagedObjectReflectable>(
        with update: @escaping (Entity) -> Entity
    ) -> UpdateClosure<Entity.ManagedObject, Entity> where Entity.ManagedObject: CoreDataEntity {

        return { managedObject in
            let updated = update(Entity(managedObject: managedObject))
            updated.reflect(to: managedObject)
            return updated
        }
    }

    private func makeFilterAndCreateClosure<Entity: ManagedObjectReflectable>(
        with allEntities: [Entity]
    ) -> FilterAndCreateClosure<Entity.ManagedObject, Entity> where Entity.ManagedObject: CoreDataEntity {

        return { existing, context in
            let newEntities = Entity.filter(existing, from: allEntities)

            let newManagedObjects: [Entity.ManagedObject] = newEntities.map {
                let managedObject = Entity.ManagedObject(context: context)
                $0.reflect(to: managedObject)
                return managedObject
            }

            return (newManagedObjects, Array(newEntities))
        }
    }
}

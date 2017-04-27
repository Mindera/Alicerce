//
//  CoreDataStack.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 03/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import CoreData

public enum CoreDataStackObjectModelLoadError: Error {
    case missingBundle(name: String, bundle: Bundle)
    case missingModel(name: String, bundle: Bundle)
    case failedToCreateModel(name: String, bundle: Bundle)
    case emptyModel(name: String, bundle: Bundle)
}

public enum CoreDataStackContextType {
    case work
    case background
}

public enum CoreDataStackStoreType {
    case inMemory
    case sqLite(storeURL: URL)

    public var nsStoreType: String {
        switch self {
        case .inMemory: return NSInMemoryStoreType
        case .sqLite: return NSSQLiteStoreType
        }
    }

    public var storeURL: URL? {
        switch self {
        case .inMemory: return nil
        case let .sqLite(url): return url
        }
    }
}

// MARK: - CoreDataStack protocol

public protocol CoreDataStack: class {

    init(storeType: CoreDataStackStoreType, storeName: String, managedObjectModel: NSManagedObjectModel)

    func context(withType type: CoreDataStackContextType) -> NSManagedObjectContext
}

// MARK: - Dependency instantiation

public extension CoreDataStack {

    // MARK: NSManagedObjectModel

    static func managedObjectModel(withBundleName bundleName: String, in bundle: Bundle) throws -> NSManagedObjectModel {

        guard
            let bundlePath = bundle.path(forResource: bundleName, ofType: "bundle"),
            let modelBundle = Bundle(path: bundlePath)
        else {
            throw CoreDataStackObjectModelLoadError.missingBundle(name: bundleName, bundle: bundle)
        }

        let modelPaths = modelBundle.paths(forResourcesOfType: "momd", inDirectory: nil)
        let models: [NSManagedObjectModel] = try modelPaths.map(URL.init(fileURLWithPath:)).map { url in
            guard let model = NSManagedObjectModel(contentsOf: url) else {
                let invalidModelName = url.deletingPathExtension().lastPathComponent
                throw CoreDataStackObjectModelLoadError.failedToCreateModel(name: invalidModelName, bundle: modelBundle)
            }

            return model
        }

        guard
            let managedObjectModel = NSManagedObjectModel(byMerging: models), // always succeeds ¯\_(ツ)_/¯
            managedObjectModel.entities.count > 0
        else {
            throw CoreDataStackObjectModelLoadError.emptyModel(name: bundleName, bundle: modelBundle)
        }

        return managedObjectModel
    }

    static func managedObjectModel(withModelName modelName: String, in bundle: Bundle) throws -> NSManagedObjectModel {

        guard let modelPath = bundle.path(forResource: modelName, ofType: "momd") else {
            throw CoreDataStackObjectModelLoadError.missingModel(name: modelName, bundle: bundle)
        }

        guard let managedObjectModel = NSManagedObjectModel(contentsOf: URL(fileURLWithPath: modelPath)) else {
            throw CoreDataStackObjectModelLoadError.failedToCreateModel(name: modelName, bundle: bundle)
        }

        guard managedObjectModel.entities.count > 0 else {
            throw CoreDataStackObjectModelLoadError.emptyModel(name: modelName, bundle: bundle)
        }

        return managedObjectModel
    }

    // MARK: NSPersistentStoreCoordinator

    static func persistentStoreCoordinator(withType storeType: CoreDataStackStoreType,
                                           storeName: String,
                                           managedObjectModel: NSManagedObjectModel,
                                           shouldAddStoreAsynchronously: Bool = false,
                                           shouldMigrateStoreAutomatically: Bool = true,
                                           shouldInferMappingModelAutomatically: Bool = true,
                                           storeLoadCompletionHandler:
                                                @escaping (String, Error?) -> Void = { (store, error) in
                                                    if let error = error {
                                                        fatalError("💥: Failed to load persistent store \(store)! Error: \(error)")
                                                    }
                                                }) -> NSPersistentStoreCoordinator {

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        let storeLoad = {
            do {
                let options: [AnyHashable : Any]? = [
                    NSMigratePersistentStoresAutomaticallyOption : shouldMigrateStoreAutomatically,
                    NSInferMappingModelAutomaticallyOption : shouldInferMappingModelAutomatically
                ]

                let persistentStore = try coordinator.addPersistentStore(ofType: storeType.nsStoreType,
                                                                         configurationName: nil,
                                                                         at: storeType.storeURL,
                                                                         options: options)

                persistentStore.identifier = storeName
                storeLoadCompletionHandler(storeName, nil)
            } catch {
                storeLoadCompletionHandler(storeName, error)
            }
        }

        shouldAddStoreAsynchronously ? DispatchQueue.global(qos: .background).async(execute: storeLoad) : storeLoad()

        return coordinator
    }

    // MARK: NSPersistentContainer

    @available(iOS 10.0, *)
    static func persistentContainer(withType storeType: CoreDataStackStoreType,
                                    name: String,
                                    managedObjectModel: NSManagedObjectModel,
                                    shouldAddStoreAsynchronously: Bool = false,
                                    shouldMigrateStoreAutomatically: Bool = true,
                                    shouldInferMappingModelAutomatically: Bool = true,
                                    storeLoadCompletionHandler:
                                        @escaping (NSPersistentStoreDescription, Error?) -> Void = { (store, error) in
                                            if let error = error {
                                                fatalError("💥: Failed to load persistent store \(store)! Error: \(error)")
                                            }
                                        }) -> NSPersistentContainer {

        let storeDescription = NSPersistentStoreDescription(storeType: storeType)
        storeDescription.shouldAddStoreAsynchronously = shouldAddStoreAsynchronously
        storeDescription.shouldMigrateStoreAutomatically = shouldMigrateStoreAutomatically
        storeDescription.shouldInferMappingModelAutomatically = shouldInferMappingModelAutomatically

        let container = NSPersistentContainer(name: name, managedObjectModel: managedObjectModel)

        container.persistentStoreDescriptions = [storeDescription]
        container.loadPersistentStores(completionHandler: storeLoadCompletionHandler)

        return container
    }
}

// MARK: - NSFetchedResultsController

public extension CoreDataStack {

    func fetchedResultsController<Entity: CoreDataEntity>(fetchRequest: NSFetchRequest<Entity>,
                                                          sectionNameKeyPath: String?,
                                                          cacheName: String?,
                                                          contextType: CoreDataStackContextType = .work)
    -> NSFetchedResultsController<Entity> {

        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: context(withType: contextType),
                                          sectionNameKeyPath: sectionNameKeyPath,
                                          cacheName: cacheName)
    }
}

// MARK: - CRUD

public extension CoreDataStack {

    typealias TransformClosure<Internal, External> = (Internal) throws -> External
    typealias CreateClosure<Internal, External> = (NSManagedObjectContext) throws -> ([Internal], [External])
    typealias UpdateClosure<Internal, External> = (Internal) throws -> External
    typealias FilterAndCreateClosure<Internal, External> = ([Internal], NSManagedObjectContext) throws -> ([Internal], [External])

    func exists<Entity: NSManagedObject>(_ entity: Entity.Type,
                                         predicate: NSPredicate,
                                         contextType: CoreDataStackContextType = .work) throws -> Bool
    where Entity: CoreDataEntity {

        let fetchRequest: NSFetchRequest<NSNumber> = Entity.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1

        let context = self.context(withType: contextType)

        return try context.performThrowingAndWait {
            return try context.count(for: fetchRequest) > 0
        }
    }

    func fetch<Internal: NSManagedObject, External>(with predicate: NSPredicate,
                                                    sortDescriptors: [NSSortDescriptor]? = nil,
                                                    fetchLimit: Int = 0,
                                                    objectsAsFaults: Bool = false,
                                                    contextType: CoreDataStackContextType = .work,
                                                    transform: @escaping TransformClosure<Internal, External>) throws -> [External]
    where Internal: CoreDataEntity {

        let fetchRequest: NSFetchRequest<Internal> = Internal.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchLimit = fetchLimit
        fetchRequest.returnsObjectsAsFaults = objectsAsFaults

        let context = self.context(withType: contextType)

        return try context.performThrowingAndWait {
            return try context.fetch(fetchRequest).map(transform)
        }
    }

    func findOrCreate<Internal: NSManagedObject, External>(with predicate: NSPredicate,
                                                           contextType: CoreDataStackContextType = .work,
                                                           filterExistingAndCreate: @escaping FilterAndCreateClosure<Internal, External>,
                                                           transform: @escaping TransformClosure<Internal, External>) throws -> [External]
    where Internal: CoreDataEntity {

        return try createOrUpdate(with: predicate,
                                  contextType: contextType,
                                  filterUpdatedAndCreate: filterExistingAndCreate,
                                  update: transform)
    }

    func create<Internal: NSManagedObject, External>(contextType: CoreDataStackContextType = .work,
                                                     create: @escaping CreateClosure<Internal, External>) throws -> [External]
    where Internal: CoreDataEntity {

        let context = self.context(withType: contextType)
        return try context.performThrowingAndWait {
            let (objects, transforms) = try create(context)

            try context.persistChanges("create \([Internal].self): \n objects: \(objects)\n transforms: \(transforms)")

            return transforms
        }
    }

    func createOrUpdate<Internal: NSManagedObject, External>(with predicate: NSPredicate,
                                                             sortDescriptors: [NSSortDescriptor]? = nil,
                                                             contextType: CoreDataStackContextType = .work,
                                                             filterUpdatedAndCreate: @escaping FilterAndCreateClosure<Internal, External>,
                                                             update: @escaping UpdateClosure<Internal, External>) throws -> [External]
    where Internal: CoreDataEntity {

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
                   "🔥: inconsistent number of created `Internal`'s and `External`'s on the `filterUpdatedAndCreate`!")
            assert(Set(createdObjects).intersection(Set(objects)).isEmpty,
                   "🔥: updated objects should't be returned on the `filterUpdatedAndCreate` closure!")

            let updated = try objects.map(update)

            try context.persistChanges("createOrUpdate \([Internal].self): \n" +
                                       "Updated (objects: \(objects), transforms: \(updated)), \n" +
                                       "Created (objects: \(createdObjects), transforms: \(created))")

            return created + updated
        }
    }

    func update<Internal: NSManagedObject, External>(with predicate: NSPredicate,
                                                     sortDescriptors: [NSSortDescriptor]? = nil,
                                                     fetchLimit: Int = 0,
                                                     contextType: CoreDataStackContextType = .work,
                                                     update: @escaping UpdateClosure<Internal, External>) throws -> [External]
    where Internal: CoreDataEntity {

        let fetchRequest: NSFetchRequest<Internal> = Internal.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchLimit = fetchLimit
        fetchRequest.returnsObjectsAsFaults = false // fire a fault to update the object's properties

        let context = self.context(withType: contextType)

        return try context.performThrowingAndWait {
            let objects = try context.fetch(fetchRequest)
            let updated = try objects.map(update)

            try context.persistChanges("update \(Internal.self):\n objects: \(objects)\n transforms: \(updated)")

            return updated
        }
    }

    func delete<Entity: NSManagedObject>(_ entity: Entity.Type, // help the type inferer if `cleanup` is nil
                                         predicate: NSPredicate,
                                         fetchLimit: Int = 0,
                                         contextType: CoreDataStackContextType = .work,
                                         cleanup: ((Entity) -> Void)? = nil) throws -> Int
    where Entity: CoreDataEntity {

        let context = self.context(withType: contextType)

        return try context.performThrowingAndWait {

            let count: Int

            // NSBatchDeleteRequest is only available on SQLite stores
            if #available(iOS 9.0, *), context.isSQLiteStoreBased(), cleanup == nil {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Entity.anyFetchRequest()
                fetchRequest.predicate = predicate
                fetchRequest.fetchLimit = fetchLimit

                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteRequest.resultType = .resultTypeObjectIDs

                guard let fetchResult = try context.execute(deleteRequest) as? NSBatchDeleteResult else {
                    fatalError("💥: Unexpected `NSPersistentStoreResult` subclass!")
                }

                guard let objectIDs = fetchResult.result as? [NSManagedObjectID] else {
                    fatalError("💥: Unexpected or `NSBatchDeleteResult`: \(String(describing: fetchResult.result))!")
                }

                if objectIDs.count > 0 {
                    let changes = [NSDeletedObjectsKey : objectIDs]
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
            try context.persistChanges("delete \(Entity.self) matching predicate: \(predicate)",
                waitForParent: true)

            return count
        }
    }

    func count<Entity: NSManagedObject>(_ entity: Entity.Type,
                                        predicate: NSPredicate,
                                        contextType: CoreDataStackContextType = .work) throws -> Int
    where Entity: CoreDataEntity {

        let fetchRequest: NSFetchRequest<NSNumber> = Entity.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.resultType = .countResultType

        let context = self.context(withType: contextType)

        return try context.performThrowingAndWait {
            return try context.count(for: fetchRequest)
        }
    }

    func performClosure<Entity: NSManagedObject>(with predicate: NSPredicate,
                                                 sortDescriptors: [NSSortDescriptor]? = nil,
                                                 fetchLimit: Int = 0,
                                                 objectsAsFaults: Bool = true,
                                                 contextType: CoreDataStackContextType = .work,
                                                 persistChanges: Bool = false,
                                                 _ closure: @escaping ([Entity]) -> Void) throws
    where Entity: CoreDataEntity {

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

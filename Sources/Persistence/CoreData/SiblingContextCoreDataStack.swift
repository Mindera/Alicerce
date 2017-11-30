//
//  SiblingContextCoreDataStack.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 03/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import CoreData

public final class SiblingContextCoreDataStack: CoreDataStack {

    fileprivate let workContext: NSManagedObjectContext
    fileprivate let backgroundContext: NSManagedObjectContext

    public required convenience init(storeType: CoreDataStackStoreType,
                              storeName: String,
                              managedObjectModel: NSManagedObjectModel) {
        self.init(storeType: storeType,
                  storeName: storeName,
                  managedObjectModel: managedObjectModel,
                  // use parameter to avoid infinite loop since Swift won't use the designated initializer below 🤷‍♂️
                  shouldAddStoreAsynchronously: false)
    }

    public init(storeType: CoreDataStackStoreType,
                storeName: String,
                managedObjectModel: NSManagedObjectModel,
                shouldAddStoreAsynchronously: Bool = false,
                shouldMigrateStoreAutomatically: Bool = true,
                shouldInferMappingModelAutomatically: Bool = true,
                storeLoadCompletionHandler: @escaping (Any, Error?) -> Void = { (store, error) in
                    if let error = error {
                        fatalError("💥: Failed to load persistent store \(store)! Error: \(error)")
                    }
                },
                mergePolicy: NSMergePolicy = NSMergePolicy(merge: .errorMergePolicyType)) {

        if #available(iOS 10.0, *) {
            let container = NestedContextCoreDataStack
                .persistentContainer(withType: storeType,
                                     name: storeName,
                                     managedObjectModel: managedObjectModel,
                                     shouldAddStoreAsynchronously: shouldAddStoreAsynchronously,
                                     shouldMigrateStoreAutomatically: shouldMigrateStoreAutomatically,
                                     shouldInferMappingModelAutomatically: shouldInferMappingModelAutomatically,
                                     storeLoadCompletionHandler: storeLoadCompletionHandler)

            workContext = container.viewContext
            workContext.automaticallyMergesChangesFromParent = true // merge changes made on sibling contexts
            workContext.mergePolicy = mergePolicy

            backgroundContext = container.newBackgroundContext()
            backgroundContext.automaticallyMergesChangesFromParent = true // merge changes made on sibling contexts
            backgroundContext.mergePolicy = mergePolicy
        } else {
            let workCoordinator = NestedContextCoreDataStack
                .persistentStoreCoordinator(withType: storeType,
                                            storeName: storeName,
                                            managedObjectModel: managedObjectModel,
                                            shouldAddStoreAsynchronously: shouldAddStoreAsynchronously,
                                            shouldMigrateStoreAutomatically: shouldMigrateStoreAutomatically,
                                            shouldInferMappingModelAutomatically: shouldInferMappingModelAutomatically,
                                            storeLoadCompletionHandler: { (store, error) in
                                                storeLoadCompletionHandler(store + " (work)", error)
                })

            workContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            workContext.persistentStoreCoordinator = workCoordinator
            workContext.mergePolicy = mergePolicy

            let backgroundCoordinator = NestedContextCoreDataStack
                .persistentStoreCoordinator(withType: storeType,
                                            storeName: storeName,
                                            managedObjectModel: managedObjectModel,
                                            shouldAddStoreAsynchronously: shouldAddStoreAsynchronously,
                                            shouldMigrateStoreAutomatically: shouldMigrateStoreAutomatically,
                                            shouldInferMappingModelAutomatically: shouldInferMappingModelAutomatically,
                                            storeLoadCompletionHandler: { (store, error) in
                                                storeLoadCompletionHandler(store + " (background)", error)
                })

            backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            backgroundContext.persistentStoreCoordinator = backgroundCoordinator
            backgroundContext.mergePolicy = mergePolicy

            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(workContextChanged),
                                                   name: .NSManagedObjectContextDidSave,
                                                   object: workContext)

            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(backgroundContextChanged),
                                                   name: .NSManagedObjectContextDidSave,
                                                   object: backgroundContext)
        }
    }

    public func context(withType type: CoreDataStackContextType) -> NSManagedObjectContext {
        switch type {
        case .work: return workContext
        case .background: return backgroundContext
        }
    }

    @objc
    private func workContextChanged(notification: Notification) {
        backgroundContext.perform { [unowned self] in
            self.backgroundContext.mergeChanges(fromContextDidSave: notification)
        }
    }

    @objc
    private func backgroundContextChanged(notification: Notification) {
        workContext.perform{ [unowned self] in
            self.workContext.mergeChanges(fromContextDidSave: notification)
        }
    }
}


// MARK: MainQueue

typealias MainQueueSiblingContextCoreDataStack = SiblingContextCoreDataStack

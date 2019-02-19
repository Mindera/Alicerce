import CoreData

public final class SiblingContextCoreDataStack: CoreDataStack {

    fileprivate let workContext: NSManagedObjectContext
    fileprivate let backgroundContext: NSManagedObjectContext

    public required convenience init(
        storeType: CoreDataStackStoreType,
        storeName: String,
        managedObjectModel: NSManagedObjectModel
    ) {

        self.init(
            storeType: storeType,
            storeName: storeName,
            managedObjectModel: managedObjectModel,
            // use parameter to avoid infinite loop since Swift won't use the designated initializer below 🤷‍♂️
            shouldAddStoreAsynchronously: false)
    }

    public init(
        storeType: CoreDataStackStoreType,
        storeName: String,
        managedObjectModel: NSManagedObjectModel,
        shouldAddStoreAsynchronously: Bool = false,
        shouldMigrateStoreAutomatically: Bool = true,
        shouldInferMappingModelAutomatically: Bool = true,
        storeLoadCompletionHandler: @escaping (Any, Error?) -> Void = { store, error in
            if let error = error {
                fatalError("💥[Alicerce.Persistence.SiblingContextCoreDataStack]: " +
                    "Failed to load persistent store \(store)! Error: \(error)")
            }
        },
        mergePolicy: NSMergePolicy = NSMergePolicy(merge: .errorMergePolicyType)
    ) {

        if #available(iOS 10.0, *) {
            (workContext, backgroundContext) = SiblingContextCoreDataStack.makeContexts(
                storeType: storeType,
                storeName: storeName,
                managedObjectModel: managedObjectModel,
                shouldAddStoreAsynchronously: shouldAddStoreAsynchronously,
                shouldMigrateStoreAutomatically: shouldMigrateStoreAutomatically,
                shouldInferMappingModelAutomatically: shouldInferMappingModelAutomatically,
                storeLoadCompletionHandler: storeLoadCompletionHandler)
        } else {
            (workContext, backgroundContext) = SiblingContextCoreDataStack.legacyMakeContexts(
                storeType: storeType,
                storeName: storeName,
                managedObjectModel: managedObjectModel,
                shouldAddStoreAsynchronously: shouldAddStoreAsynchronously,
                shouldMigrateStoreAutomatically: shouldMigrateStoreAutomatically,
                shouldInferMappingModelAutomatically: shouldInferMappingModelAutomatically,
                storeLoadCompletionHandler: storeLoadCompletionHandler)

            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(workContextChanged),
                                                   name: .NSManagedObjectContextDidSave,
                                                   object: workContext)

            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(backgroundContextChanged),
                                                   name: .NSManagedObjectContextDidSave,
                                                   object: backgroundContext)
        }

        workContext.mergePolicy = mergePolicy
        backgroundContext.mergePolicy = mergePolicy
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

        workContext.perform { [unowned self] in
            self.workContext.mergeChanges(fromContextDidSave: notification)
        }
    }
}

// MARK: Helpers

extension SiblingContextCoreDataStack {

    @available(iOS 10.0, *)
    // swiftlint:disable:next function_parameter_count
    static func makeContexts(
        storeType: CoreDataStackStoreType,
        storeName: String,
        managedObjectModel: NSManagedObjectModel,
        shouldAddStoreAsynchronously: Bool,
        shouldMigrateStoreAutomatically: Bool,
        shouldInferMappingModelAutomatically: Bool,
        storeLoadCompletionHandler: @escaping (Any, Error?) -> Void
    ) -> (work: NSManagedObjectContext, background: NSManagedObjectContext) {

        let container = NestedContextCoreDataStack.persistentContainer(
            withType: storeType,
            name: storeName,
            managedObjectModel: managedObjectModel,
            shouldAddStoreAsynchronously: shouldAddStoreAsynchronously,
            shouldMigrateStoreAutomatically: shouldMigrateStoreAutomatically,
            shouldInferMappingModelAutomatically: shouldInferMappingModelAutomatically,
            storeLoadCompletionHandler: storeLoadCompletionHandler)

        let workContext = container.viewContext
        workContext.automaticallyMergesChangesFromParent = true // merge changes made on sibling contexts

        let backgroundContext = container.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true // merge changes made on sibling contexts

        return (workContext, backgroundContext)
    }

    // TODO: remove this method when on iOS 10+
    // swiftlint:disable:next function_parameter_count
    static func legacyMakeContexts(
        storeType: CoreDataStackStoreType,
        storeName: String,
        managedObjectModel: NSManagedObjectModel,
        shouldAddStoreAsynchronously: Bool,
        shouldMigrateStoreAutomatically: Bool,
        shouldInferMappingModelAutomatically: Bool,
        storeLoadCompletionHandler: @escaping (Any, Error?) -> Void
    ) -> (work: NSManagedObjectContext, background: NSManagedObjectContext) {

        let workCoordinator = NestedContextCoreDataStack.persistentStoreCoordinator(
            withType: storeType,
            storeName: storeName,
            managedObjectModel: managedObjectModel,
            shouldAddStoreAsynchronously: shouldAddStoreAsynchronously,
            shouldMigrateStoreAutomatically: shouldMigrateStoreAutomatically,
            shouldInferMappingModelAutomatically: shouldInferMappingModelAutomatically,
            storeLoadCompletionHandler: { store, error in storeLoadCompletionHandler(store + " (work)", error) })

        let workContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        workContext.persistentStoreCoordinator = workCoordinator

        let backgroundCoordinator = NestedContextCoreDataStack.persistentStoreCoordinator(
            withType: storeType,
            storeName: storeName,
            managedObjectModel: managedObjectModel,
            shouldAddStoreAsynchronously: shouldAddStoreAsynchronously,
            shouldMigrateStoreAutomatically: shouldMigrateStoreAutomatically,
            shouldInferMappingModelAutomatically: shouldInferMappingModelAutomatically,
            storeLoadCompletionHandler: { store, error in storeLoadCompletionHandler(store + " (background)", error) })

        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.persistentStoreCoordinator = backgroundCoordinator

        return (workContext, backgroundContext)
    }
}

// MARK: MainQueue

typealias MainQueueSiblingContextCoreDataStack = SiblingContextCoreDataStack

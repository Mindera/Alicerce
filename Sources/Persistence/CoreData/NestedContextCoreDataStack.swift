import CoreData

open class NestedContextCoreDataStack: CoreDataStack {

    fileprivate let backgroundContext: NSManagedObjectContext
    fileprivate let workContext: NSManagedObjectContext

    public convenience required init(storeType: CoreDataStackStoreType,
                                     storeName: String,
                                     managedObjectModel: NSManagedObjectModel) {
        self.init(storeType: storeType,
                  storeName: storeName,
                  managedObjectModel: managedObjectModel,
                  // use parameter to avoid infinite loop since Swift won't use the designated initializer below 🤷‍♂️
                  shouldAddStoreAsynchronously: false)
    }

    // swiftlint:disable:next multiline_parameters
    public init(storeType: CoreDataStackStoreType,
                storeName: String,
                managedObjectModel: NSManagedObjectModel,
                shouldAddStoreAsynchronously: Bool = false,
                shouldMigrateStoreAutomatically: Bool = true,
                shouldInferMappingModelAutomatically: Bool = true,
                storeLoadCompletionHandler: @escaping (Any, Error?) -> Void = { store, error in
                    if let error = error {
                        fatalError("💥: Failed to load persistent store \(store)! Error: \(error)")
                    }
                },
                workContextConcurrencyType: NSManagedObjectContextConcurrencyType = .privateQueueConcurrencyType,
                mergePolicy: NSMergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)) {

        if #available(iOS 10.0, *) {
            let container = NestedContextCoreDataStack
                .persistentContainer(withType: storeType,
                                     name: storeName,
                                     managedObjectModel: managedObjectModel,
                                     shouldAddStoreAsynchronously: shouldAddStoreAsynchronously,
                                     shouldMigrateStoreAutomatically: shouldMigrateStoreAutomatically,
                                     shouldInferMappingModelAutomatically: shouldInferMappingModelAutomatically,
                                     storeLoadCompletionHandler: storeLoadCompletionHandler)

            backgroundContext = container.newBackgroundContext()
        } else {
            let coordinator = NestedContextCoreDataStack
                .persistentStoreCoordinator(withType: storeType,
                                            storeName: storeName,
                                            managedObjectModel: managedObjectModel,
                                            shouldAddStoreAsynchronously: shouldAddStoreAsynchronously,
                                            shouldMigrateStoreAutomatically: shouldMigrateStoreAutomatically,
                                            shouldInferMappingModelAutomatically: shouldInferMappingModelAutomatically,
                                            storeLoadCompletionHandler: storeLoadCompletionHandler)

            backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            backgroundContext.persistentStoreCoordinator = coordinator
        }

        backgroundContext.mergePolicy = mergePolicy
        backgroundContext.name = "Background (persisting)"

        workContext = NSManagedObjectContext(concurrencyType: workContextConcurrencyType)
        workContext.parent = backgroundContext
        workContext.name = "Work (\(workContextConcurrencyType.typeString))"
        workContext.mergePolicy = mergePolicy
    }

    public func context(withType type: CoreDataStackContextType) -> NSManagedObjectContext {
        switch type {
        case .work: return workContext
        case .background: return backgroundContext
        }
    }
}

// MARK: MainQueue

public final class MainQueueNestedContextCoreDataStack: NestedContextCoreDataStack {

    public required init(storeType: CoreDataStackStoreType,
                         storeName: String,
                         managedObjectModel: NSManagedObjectModel) {
        super.init(storeType: storeType,
                   storeName: storeName,
                   managedObjectModel: managedObjectModel,
                   workContextConcurrencyType: .mainQueueConcurrencyType)
    }
}

// MARK: PrivateQueue

public typealias PrivateQueueNestedContextCoreDataStack = NestedContextCoreDataStack

// MARK: Utils

extension NSManagedObjectContextConcurrencyType {
    var typeString: String {
        switch self {
        case .confinementConcurrencyType: return "confinement"
        case .mainQueueConcurrencyType: return "mainQueue"
        case .privateQueueConcurrencyType: return "privateQueue"
        }
    }
}

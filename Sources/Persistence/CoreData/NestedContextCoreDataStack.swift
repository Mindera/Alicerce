import CoreData

open class NestedContextCoreDataStack: CoreDataStack {

    fileprivate let backgroundContext: NSManagedObjectContext
    fileprivate let workContext: NSManagedObjectContext

    public convenience required init(
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
                fatalError("💥 Failed to load persistent store \(store)! Error: \(error)")
            }
        },
        workContextConcurrencyType: NSManagedObjectContextConcurrencyType = .privateQueueConcurrencyType,
        mergePolicy: NSMergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
    ) {

        if #available(iOS 10.0, *) {
            backgroundContext = NestedContextCoreDataStack.makeBackgroundContext(
                storeType: storeType,
                storeName: storeName,
                managedObjectModel: managedObjectModel,
                shouldAddStoreAsynchronously: shouldAddStoreAsynchronously,
                shouldMigrateStoreAutomatically: shouldMigrateStoreAutomatically,
                shouldInferMappingModelAutomatically: shouldInferMappingModelAutomatically,
                storeLoadCompletionHandler: storeLoadCompletionHandler)
        } else {
            backgroundContext = NestedContextCoreDataStack.legacyMakeBackgroundContext(
                storeType: storeType,
                storeName: storeName,
                managedObjectModel: managedObjectModel,
                shouldAddStoreAsynchronously: shouldAddStoreAsynchronously,
                shouldMigrateStoreAutomatically: shouldMigrateStoreAutomatically,
                shouldInferMappingModelAutomatically: shouldInferMappingModelAutomatically,
                storeLoadCompletionHandler: storeLoadCompletionHandler)
        }

        backgroundContext.name = "Background (persisting)"
        backgroundContext.mergePolicy = mergePolicy

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

extension NestedContextCoreDataStack {

    @available(iOS 10.0, *)
    // swiftlint:disable:next function_parameter_count
    static func makeBackgroundContext(
        storeType: CoreDataStackStoreType,
        storeName: String,
        managedObjectModel: NSManagedObjectModel,
        shouldAddStoreAsynchronously: Bool,
        shouldMigrateStoreAutomatically: Bool,
        shouldInferMappingModelAutomatically: Bool,
        storeLoadCompletionHandler: @escaping (Any, Error?) -> Void
    ) -> NSManagedObjectContext {

        let container = NestedContextCoreDataStack.persistentContainer(
            withType: storeType,
            name: storeName,
            managedObjectModel: managedObjectModel,
            shouldAddStoreAsynchronously: shouldAddStoreAsynchronously,
            shouldMigrateStoreAutomatically: shouldMigrateStoreAutomatically,
            shouldInferMappingModelAutomatically: shouldInferMappingModelAutomatically,
            storeLoadCompletionHandler: storeLoadCompletionHandler)

        return container.newBackgroundContext()
    }

    // TODO: remove this method when on iOS 10+
    // swiftlint:disable:next function_parameter_count
    static func legacyMakeBackgroundContext(
        storeType: CoreDataStackStoreType,
        storeName: String,
        managedObjectModel: NSManagedObjectModel,
        shouldAddStoreAsynchronously: Bool,
        shouldMigrateStoreAutomatically: Bool,
        shouldInferMappingModelAutomatically: Bool,
        storeLoadCompletionHandler: @escaping (Any, Error?) -> Void
    ) -> NSManagedObjectContext {

        let coordinator = NestedContextCoreDataStack.persistentStoreCoordinator(
            withType: storeType,
            storeName: storeName,
            managedObjectModel: managedObjectModel,
            shouldAddStoreAsynchronously: shouldAddStoreAsynchronously,
            shouldMigrateStoreAutomatically: shouldMigrateStoreAutomatically,
            shouldInferMappingModelAutomatically: shouldInferMappingModelAutomatically,
            storeLoadCompletionHandler: storeLoadCompletionHandler)

        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.persistentStoreCoordinator = coordinator

        return backgroundContext
    }
}

// MARK: MainQueue

public final class MainQueueNestedContextCoreDataStack: NestedContextCoreDataStack {

    public required init(
        storeType: CoreDataStackStoreType,
        storeName: String,
        managedObjectModel: NSManagedObjectModel
    ) {

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
        @unknown
        default: return "unknown"
        }
    }
}

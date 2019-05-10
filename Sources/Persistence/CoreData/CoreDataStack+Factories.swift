import CoreData

public extension CoreDataStack {

    // MARK: NSManagedObjectModel

    static func managedObjectModel(
        withBundleName bundleName: String,
        in bundle: Bundle
    ) throws -> NSManagedObjectModel {

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
            managedObjectModel.entities.isEmpty == false
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

        guard managedObjectModel.entities.isEmpty == false else {
            throw CoreDataStackObjectModelLoadError.emptyModel(name: modelName, bundle: bundle)
        }

        return managedObjectModel
    }

    // MARK: NSPersistentContainer

    static func persistentContainer(
        withType storeType: CoreDataStackStoreType,
        name: String,
        managedObjectModel: NSManagedObjectModel,
        shouldAddStoreAsynchronously: Bool = false,
        shouldMigrateStoreAutomatically: Bool = true,
        shouldInferMappingModelAutomatically: Bool = true,
        storeLoadCompletionHandler: @escaping (NSPersistentStoreDescription, Error?) -> Void = { store, error in
            if let error = error {
                fatalError("💥 Failed to load persistent store \(store)! Error: \(error)")
            }
        }
    ) -> NSPersistentContainer {

        let storeDescription = NSPersistentStoreDescription(storeType: storeType)
        storeDescription.shouldAddStoreAsynchronously = shouldAddStoreAsynchronously
        storeDescription.shouldMigrateStoreAutomatically = shouldMigrateStoreAutomatically
        storeDescription.shouldInferMappingModelAutomatically = shouldInferMappingModelAutomatically

        let container = NSPersistentContainer(name: name, managedObjectModel: managedObjectModel)

        container.persistentStoreDescriptions = [storeDescription]
        container.loadPersistentStores(completionHandler: storeLoadCompletionHandler)

        return container
    }

    // MARK: NSFetchedResultsController

    func fetchedResultsController<Entity: CoreDataEntity>(
        fetchRequest: NSFetchRequest<Entity>,
        sectionNameKeyPath: String?,
        cacheName: String?,
        contextType: CoreDataStackContextType = .work
    ) -> NSFetchedResultsController<Entity> {

        return NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context(withType: contextType),
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: cacheName)
    }
}

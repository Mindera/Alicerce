import CoreData

public extension NSPersistentStoreCoordinator {

    func firstStoreType() -> CoreDataStackStoreType {
        guard let firstStore = persistentStores.first else {
            fatalError("💥: Persistent Store Coordinator must have at least one store!")
        }

        switch (firstStore.type, firstStore.url) {
        case (NSInMemoryStoreType, _): return .inMemory
        case (NSSQLiteStoreType, let url?): return .sqLite(storeURL: url)
        default: fatalError("💥: Unsupported persistent store type \(firstStore.type)!")
        }
    }
}

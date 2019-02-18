import CoreData

public enum CoreDataStackObjectModelLoadError: Error {
    case missingBundle(name: String, bundle: Bundle)
    case missingModel(name: String, bundle: Bundle)
    case failedToCreateModel(name: String, bundle: Bundle)
    case emptyModel(name: String, bundle: Bundle)
}

public enum CoreDataStackContextType: Equatable {
    case work
    case background
}

public enum CoreDataStackStoreType: Equatable {
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

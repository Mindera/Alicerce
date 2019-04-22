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
    case sqlite(storeURL: URL)

    public var nsStoreType: String {
        switch self {
        case .inMemory: return NSInMemoryStoreType
        case .sqlite: return NSSQLiteStoreType
        }
    }

    public var storeURL: URL? {
        switch self {
        case .inMemory: return nil
        case let .sqlite(url): return url
        }
    }
}

// MARK: - CoreDataStack protocol

public protocol CoreDataStack: AnyObject {

    init(storeType: CoreDataStackStoreType, storeName: String, managedObjectModel: NSManagedObjectModel)

    func context(withType type: CoreDataStackContextType) -> NSManagedObjectContext
}

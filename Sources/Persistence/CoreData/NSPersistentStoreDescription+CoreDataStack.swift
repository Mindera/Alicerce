import CoreData

public extension NSPersistentStoreDescription {

    convenience init(storeType: CoreDataStackStoreType) {
        switch storeType {
        case .inMemory:
            self.init()
            self.type = NSInMemoryStoreType
        case let .sqlite(url):
            self.init(url: url)
            self.type = NSSQLiteStoreType
        }
    }
}

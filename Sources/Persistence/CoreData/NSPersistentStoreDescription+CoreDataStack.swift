import CoreData

@available(iOS 10.0, *)
public extension NSPersistentStoreDescription {

    convenience init(storeType: CoreDataStackStoreType) {
        switch storeType {
        case .inMemory:
            self.init()
            self.type = NSInMemoryStoreType
        case let .sqLite(url):
            self.init(url: url)
            self.type = NSSQLiteStoreType
        }
    }
}

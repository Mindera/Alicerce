import Foundation
@testable import Alicerce

class MockCoreDataStack: CoreDataStack {

    var mockBackgroundContext: NSManagedObjectContext {
        didSet { mockBackgroundContext.persistentStoreCoordinator = container.persistentStoreCoordinator }
    }

    var mockWorkContext: NSManagedObjectContext {
        didSet { mockWorkContext.parent = mockBackgroundContext }
    }

    fileprivate let container: NSPersistentContainer

    required init(storeType: CoreDataStackStoreType, storeName: String, managedObjectModel: NSManagedObjectModel) {

        container = MockCoreDataStack.persistentContainer(withType: storeType,
                                                          name: storeName,
                                                          managedObjectModel: managedObjectModel)

        mockBackgroundContext = container.newBackgroundContext()

        mockWorkContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mockWorkContext.parent = mockBackgroundContext
    }

    func context(withType type: CoreDataStackContextType) -> NSManagedObjectContext {
        switch type {
        case .work: return mockWorkContext
        case .background: return mockBackgroundContext
        }
    }
}

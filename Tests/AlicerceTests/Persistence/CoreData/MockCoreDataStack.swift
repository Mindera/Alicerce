import Foundation
@testable import Alicerce

class MockCoreDataStack: CoreDataStack {

    var mockBackgroundContext: NSManagedObjectContext {
        didSet { mockBackgroundContext.persistentStoreCoordinator = coordinator }
    }

    var mockWorkContext: NSManagedObjectContext {
        didSet { mockWorkContext.parent = mockBackgroundContext }
    }

    fileprivate let coordinator: NSPersistentStoreCoordinator

    required init(storeType: CoreDataStackStoreType, storeName: String, managedObjectModel: NSManagedObjectModel) {

        coordinator = MockCoreDataStack.persistentStoreCoordinator(withType: storeType,
                                                                   storeName: storeName,
                                                                   managedObjectModel: managedObjectModel)

        mockBackgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        mockBackgroundContext.persistentStoreCoordinator = coordinator

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

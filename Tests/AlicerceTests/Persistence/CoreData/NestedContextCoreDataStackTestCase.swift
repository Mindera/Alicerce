import XCTest
@testable import Alicerce

class NestedContextCoreDataStackTestCase: XCTestCase {

    private let testModelName = "CoreDataStackModel"
    private let testModelBundleName = "CoreDataStackModel"

    private var libraryDirectory: URL {
        return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
    }

    private var testBundle: Bundle {
        return Bundle(for: type(of: self))
    }

    private var testManagedObjectModel: NSManagedObjectModel {
        return try! NestedContextCoreDataStack.managedObjectModel(withModelName: testModelName, in: testBundle)
    }

    // MARK: - NestedContextCoreDataStack (PrivateQueueNestedContextCoreDataStack)

    // MARK: init

    func testInit_WithInMemoryStoreType_ShouldSucceed() {

        let testStoreName = "test"

        let stack = NestedContextCoreDataStack(storeType: .inMemory,
                                               storeName: testStoreName,
                                               managedObjectModel: testManagedObjectModel)

        let workContext = stack.context(withType: .work)
        let backgroundContext = stack.context(withType: .background)

        XCTAssertEqual(workContext.persistentStoreCoordinator?.firstStoreType, .inMemory)
        XCTAssertEqual(workContext.persistentStoreCoordinator?.managedObjectModel, testManagedObjectModel)
        XCTAssertEqual(workContext.concurrencyType, .privateQueueConcurrencyType)
        XCTAssertEqual(workContext.parent, backgroundContext)
        XCTAssertEqual((workContext.mergePolicy as? NSMergePolicy)?.mergeType,
                       .mergeByPropertyStoreTrumpMergePolicyType)
        
        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.firstStoreType, .inMemory)
        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.managedObjectModel, testManagedObjectModel)
        XCTAssertEqual(backgroundContext.concurrencyType, .privateQueueConcurrencyType)
    }

    func testInit_WithSQLiteStoreType_ShouldSucceed() {

        let testStoreName = "test"
        let testStoreURL = libraryDirectory.appendingPathComponent("testStore.sqlite")
        let testStoreType = CoreDataStackStoreType.sqlite(storeURL: testStoreURL)

        let stack = NestedContextCoreDataStack(storeType: testStoreType,
                                               storeName: testStoreName,
                                               managedObjectModel: testManagedObjectModel)

        let workContext = stack.context(withType: .work)
        let backgroundContext = stack.context(withType: .background)

        XCTAssertEqual(workContext.persistentStoreCoordinator?.firstStoreType, testStoreType)
        XCTAssertEqual(workContext.persistentStoreCoordinator?.managedObjectModel, testManagedObjectModel)
        XCTAssertEqual(workContext.concurrencyType, .privateQueueConcurrencyType)
        XCTAssertEqual(workContext.parent, backgroundContext)
        XCTAssertEqual((workContext.mergePolicy as? NSMergePolicy)?.mergeType,
                       .mergeByPropertyStoreTrumpMergePolicyType)

        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.firstStoreType, testStoreType)
        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.managedObjectModel, testManagedObjectModel)
        XCTAssertEqual(backgroundContext.concurrencyType, .privateQueueConcurrencyType)
    }

    // MARK: makeBackgroundContext

    func testMakeBackgroundContext_WithInMemoryStoreType_ShouldSucceed() {

        let loadExpectation = expectation(description: "storeLoad")
        defer { waitForExpectations(timeout: 1) }

        let testStoreName = "test"

        let backgroundContext = NestedContextCoreDataStack.makeBackgroundContext(
            storeType: .inMemory,
            storeName: testStoreName,
            managedObjectModel: testManagedObjectModel,
            shouldAddStoreAsynchronously: false,
            shouldMigrateStoreAutomatically: true,
            shouldInferMappingModelAutomatically: true,
            storeLoadCompletionHandler: { _, _ in loadExpectation.fulfill() })

        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.firstStoreType, .inMemory)
        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.managedObjectModel, testManagedObjectModel)
        XCTAssertEqual(backgroundContext.concurrencyType, .privateQueueConcurrencyType)
    }

    func testMakeBackgroundContext_WithSQLiteStoreType_ShouldSucceed() {

        let loadExpectation = expectation(description: "storeLoad")
        defer { waitForExpectations(timeout: 1) }

        let testStoreName = "test"
        let testStoreURL = libraryDirectory.appendingPathComponent("testStore.sqlite")
        let testStoreType = CoreDataStackStoreType.sqlite(storeURL: testStoreURL)

        let backgroundContext = NestedContextCoreDataStack.makeBackgroundContext(
            storeType: testStoreType,
            storeName: testStoreName,
            managedObjectModel: testManagedObjectModel,
            shouldAddStoreAsynchronously: false,
            shouldMigrateStoreAutomatically: true,
            shouldInferMappingModelAutomatically: true,
            storeLoadCompletionHandler: { _, _ in loadExpectation.fulfill() })

        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.firstStoreType, testStoreType)
        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.managedObjectModel, testManagedObjectModel)
        XCTAssertEqual(backgroundContext.concurrencyType, .privateQueueConcurrencyType)
    }

    // MARK: - MainQueueNestedContextCoreDataStack

    func testMainQueueInit_WithInMemoryStoreType_ShouldSucceed() {

        let testStoreName = "test"

        let stack = MainQueueNestedContextCoreDataStack(storeType: .inMemory,
                                                        storeName: testStoreName,
                                                        managedObjectModel: testManagedObjectModel)

        let workContext = stack.context(withType: .work)
        let backgroundContext = stack.context(withType: .background)

        XCTAssertEqual(workContext.persistentStoreCoordinator?.firstStoreType, .inMemory)
        XCTAssertEqual(workContext.persistentStoreCoordinator?.managedObjectModel, testManagedObjectModel)
        XCTAssertEqual(workContext.concurrencyType, .mainQueueConcurrencyType)
        XCTAssertEqual(workContext.parent, backgroundContext)
        XCTAssertEqual((workContext.mergePolicy as? NSMergePolicy)?.mergeType,
                       .mergeByPropertyStoreTrumpMergePolicyType)
        
        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.firstStoreType, .inMemory)
        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.managedObjectModel, testManagedObjectModel)
        XCTAssertEqual(backgroundContext.concurrencyType, .privateQueueConcurrencyType)
    }

    func testMainQueueInit_WithSQLiteStoreType_ShouldSucceed() {

        let testStoreName = "test"
        let testStoreURL = libraryDirectory.appendingPathComponent("testStore.sqlite")
        let testStoreType = CoreDataStackStoreType.sqlite(storeURL: testStoreURL)

        let stack = MainQueueNestedContextCoreDataStack(storeType: testStoreType,
                                                        storeName: testStoreName,
                                                        managedObjectModel: testManagedObjectModel)

        let workContext = stack.context(withType: .work)
        let backgroundContext = stack.context(withType: .background)

        XCTAssertEqual(workContext.persistentStoreCoordinator?.firstStoreType, testStoreType)
        XCTAssertEqual(workContext.persistentStoreCoordinator?.managedObjectModel, testManagedObjectModel)
        XCTAssertEqual(workContext.concurrencyType, .mainQueueConcurrencyType)
        XCTAssertEqual(workContext.parent, backgroundContext)
        XCTAssertEqual((workContext.mergePolicy as? NSMergePolicy)?.mergeType,
                       .mergeByPropertyStoreTrumpMergePolicyType)

        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.firstStoreType, testStoreType)
        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.managedObjectModel, testManagedObjectModel)
        XCTAssertEqual(backgroundContext.concurrencyType, .privateQueueConcurrencyType)
    }
}

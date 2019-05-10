import XCTest
@testable import Alicerce

class SiblingContextCoreDataStackTestCase: XCTestCase {

    private let testModelName = "CoreDataStackModel"
    private let testModelBundleName = "CoreDataStackModel"

    private var libraryDirectory: URL {
        return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
    }

    private var testBundle: Bundle {
        return Bundle(for: type(of: self))
    }

    private var testManagedObjectModel: NSManagedObjectModel {
        return try! SiblingContextCoreDataStack.managedObjectModel(withModelName: testModelName, in: testBundle)
    }

    // MARK: init

    func testInit_WithInMemoryStoreType_ShouldSucceed() {

        let testStoreName = "test"

        let stack = SiblingContextCoreDataStack(storeType: .inMemory,
                                                storeName: testStoreName,
                                                managedObjectModel: testManagedObjectModel)

        let workContext = stack.context(withType: .work)
        let backgroundContext = stack.context(withType: .background)

        XCTAssertEqual(workContext.persistentStoreCoordinator?.firstStoreType, .inMemory)
        XCTAssertEqual(workContext.persistentStoreCoordinator?.managedObjectModel, testManagedObjectModel)
        XCTAssertEqual(workContext.concurrencyType, .mainQueueConcurrencyType)
        XCTAssertEqual(workContext.automaticallyMergesChangesFromParent, true)
        XCTAssertEqual((workContext.mergePolicy as? NSMergePolicy)?.mergeType, .errorMergePolicyType)

        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.firstStoreType, .inMemory)
        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.managedObjectModel, testManagedObjectModel)
        XCTAssertEqual(backgroundContext.concurrencyType, .privateQueueConcurrencyType)
        XCTAssertEqual(backgroundContext.automaticallyMergesChangesFromParent, true)
        XCTAssertEqual((backgroundContext.mergePolicy as? NSMergePolicy)?.mergeType, .errorMergePolicyType)
    }

    func testInit_WithSQLiteStoreType_ShouldSucceed() {

        let testStoreName = "test"
        let testStoreURL = libraryDirectory.appendingPathComponent("testStore.sqlite")
        let testStoreType = CoreDataStackStoreType.sqlite(storeURL: testStoreURL)

        let stack = SiblingContextCoreDataStack(storeType: testStoreType,
                                                storeName: testStoreName,
                                                managedObjectModel: testManagedObjectModel)

        let workContext = stack.context(withType: .work)
        let backgroundContext = stack.context(withType: .background)

        XCTAssertEqual(workContext.persistentStoreCoordinator?.firstStoreType, testStoreType)
        XCTAssertEqual(workContext.persistentStoreCoordinator?.managedObjectModel, testManagedObjectModel)
        XCTAssertEqual(workContext.concurrencyType, .mainQueueConcurrencyType)
        XCTAssertEqual(workContext.automaticallyMergesChangesFromParent, true)
        XCTAssertEqual((workContext.mergePolicy as? NSMergePolicy)?.mergeType, .errorMergePolicyType)

        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.firstStoreType, testStoreType)
        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.managedObjectModel, testManagedObjectModel)
        XCTAssertEqual(backgroundContext.concurrencyType, .privateQueueConcurrencyType)
        XCTAssertEqual(backgroundContext.automaticallyMergesChangesFromParent, true)
        XCTAssertEqual((backgroundContext.mergePolicy as? NSMergePolicy)?.mergeType, .errorMergePolicyType)
    }

    // MARK: makeContexts

    func testMakeContexts_WithInMemoryStoreType_ShouldSucceed() {

        let loadExpectation = expectation(description: "storeLoad")
        defer { waitForExpectations(timeout: 1) }

        let testStoreName = "test"

        let (workContext, backgroundContext) = SiblingContextCoreDataStack.makeContexts(
            storeType: .inMemory,
            storeName: testStoreName,
            managedObjectModel: testManagedObjectModel,
            shouldAddStoreAsynchronously: false,
            shouldMigrateStoreAutomatically: true,
            shouldInferMappingModelAutomatically: true,
            storeLoadCompletionHandler: { _, _ in loadExpectation.fulfill() })

        XCTAssertEqual(workContext.persistentStoreCoordinator?.firstStoreType, .inMemory)
        XCTAssertEqual(workContext.persistentStoreCoordinator?.managedObjectModel, testManagedObjectModel)
        XCTAssertEqual(workContext.concurrencyType, .mainQueueConcurrencyType)
        XCTAssertEqual(workContext.automaticallyMergesChangesFromParent, true)

        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.firstStoreType, .inMemory)
        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.managedObjectModel, testManagedObjectModel)
        XCTAssertEqual(backgroundContext.concurrencyType, .privateQueueConcurrencyType)
        XCTAssertEqual(backgroundContext.automaticallyMergesChangesFromParent, true)
    }

    func testMakeContexts_WithSQLiteStoreType_ShouldSucceed() {

        let loadExpectation = expectation(description: "storeLoad")
        defer { waitForExpectations(timeout: 1) }

        let testStoreName = "test"
        let testStoreURL = libraryDirectory.appendingPathComponent("testStore.sqlite")
        let testStoreType = CoreDataStackStoreType.sqlite(storeURL: testStoreURL)

        let (workContext, backgroundContext) = SiblingContextCoreDataStack.makeContexts(
            storeType: testStoreType,
            storeName: testStoreName,
            managedObjectModel: testManagedObjectModel,
            shouldAddStoreAsynchronously: false,
            shouldMigrateStoreAutomatically: true,
            shouldInferMappingModelAutomatically: true,
            storeLoadCompletionHandler: { _, _ in loadExpectation.fulfill() })

        XCTAssertEqual(workContext.persistentStoreCoordinator?.firstStoreType, testStoreType)
        XCTAssertEqual(workContext.persistentStoreCoordinator?.managedObjectModel, testManagedObjectModel)
        XCTAssertEqual(workContext.concurrencyType, .mainQueueConcurrencyType)
        XCTAssertEqual(workContext.automaticallyMergesChangesFromParent, true)

        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.firstStoreType, testStoreType)
        XCTAssertEqual(backgroundContext.persistentStoreCoordinator?.managedObjectModel, testManagedObjectModel)
        XCTAssertEqual(backgroundContext.concurrencyType, .privateQueueConcurrencyType)
        XCTAssertEqual(backgroundContext.automaticallyMergesChangesFromParent, true)
    }
}


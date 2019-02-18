import XCTest
@testable import Alicerce

class CoreDataStack_FactoriesTestCase: XCTestCase {

    fileprivate let expectationTimeout: TimeInterval = 5
    fileprivate let expectationHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("🔥: Test expectation wait timed out: \(error)")
        }
    }

    fileprivate var libraryDirectory: URL {
        return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
    }

    fileprivate let testModelName = "CoreDataStackModel"
    fileprivate let testModelBundleName = "CoreDataStackModel"

    fileprivate var testBundle: Bundle {
        return Bundle(for: type(of: self))
    }

    fileprivate var testManagedObjectModel: NSManagedObjectModel {
        return try! MockCoreDataStack.managedObjectModel(withModelName: testModelName, in: testBundle)
    }

    // MARK: - managedObjectModel(withBundleName:in:)

    func testManagedObjectModelWithBundleName_WithValidBundleNameAndBundle_ShouldSucceed() {

        do {
            let _ = try MockCoreDataStack.managedObjectModel(withBundleName: testModelBundleName, in: testBundle)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testManagedObjectModelWithBundleName_WithInvalidBundleName_ShouldFailWithMissingBundleError() {

        let invalidTestBundleName = "invalid"

        do {
            let _ = try MockCoreDataStack.managedObjectModel(withBundleName: invalidTestBundleName, in: testBundle)
        } catch let CoreDataStackObjectModelLoadError.missingBundle(bundleName, bundle) {
            XCTAssertEqual(bundleName, invalidTestBundleName)
            XCTAssertEqual(bundle, testBundle)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testManagedObjectModelWithBundleName_WithInvalidModelInBundle_ShouldFailWithFailedToCreateError() {

        let invalidTestModelBundleName = "InvalidCoreDataStackModel"
        let invalidTestModelName = "InvalidCoreDataModel"

        guard
            let bundlePath = testBundle.path(forResource: invalidTestModelBundleName, ofType: "bundle"),
            let invalidTestModelBundle = Bundle(path: bundlePath)
        else {
            return XCTFail("🔥: failed to load invalid test model bundle")
        }

        do {
            let _ = try MockCoreDataStack.managedObjectModel(withBundleName: invalidTestModelBundleName, in: testBundle)
        } catch let CoreDataStackObjectModelLoadError.failedToCreateModel(name, bundle) {
            XCTAssertEqual(name, invalidTestModelName)
            XCTAssertEqual(bundle, invalidTestModelBundle)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testManagedObjectModelWithBundleName_WithEmptyBundle_ShouldFailWithEmptyModelError() {

        let emptyTestModelBundleName = "EmptyCoreDataStackModel"

        guard
            let bundlePath = testBundle.path(forResource: emptyTestModelBundleName, ofType: "bundle"),
            let emptyTestModelBundle = Bundle(path: bundlePath)
        else {
            return XCTFail("🔥: failed to load empty test model bundle")
        }

        do {
            let _ = try MockCoreDataStack.managedObjectModel(withBundleName: emptyTestModelBundleName, in: testBundle)
        } catch let CoreDataStackObjectModelLoadError.emptyModel(name, bundle) {
            XCTAssertEqual(name, emptyTestModelBundleName)
            XCTAssertEqual(bundle, emptyTestModelBundle)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    // MARK: - managedObjectModel(withModelName:in:)

    func testManagedObjectModelWithModelName_WithValidModelameAndBundle_ShouldSucceed() {

        do {
            let _ = try MockCoreDataStack.managedObjectModel(withModelName: testModelName, in: testBundle)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testManagedObjectModelWithModelName_WithNonExistentModelName_ShouldFailWithMissingBundleError() {

        let nonExistentTestModelName = "non-existent"

        do {
            let _ = try MockCoreDataStack.managedObjectModel(withModelName: nonExistentTestModelName, in: testBundle)
        } catch let CoreDataStackObjectModelLoadError.missingModel(modelName, bundle) {
            XCTAssertEqual(modelName, nonExistentTestModelName)
            XCTAssertEqual(bundle, testBundle)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testManagedObjectModelWithModelName_WithInvalidModel_ShouldFailWithFailedToCreateError() {

        let invalidTestModelName = "InvalidCoreDataModel"

        do {
            let _ = try MockCoreDataStack.managedObjectModel(withModelName: invalidTestModelName, in: testBundle)
        } catch let CoreDataStackObjectModelLoadError.failedToCreateModel(modelName, bundle) {
            XCTAssertEqual(modelName, invalidTestModelName)
            XCTAssertEqual(bundle, testBundle)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testManagedObjectModelWithModelName_WithEmptyBundle_ShouldFailWithEmptyModelError() {

        let emptyTestModelName = "EmptyCoreDataStackModel"

        do {
            let _ = try MockCoreDataStack.managedObjectModel(withModelName: emptyTestModelName, in: testBundle)
        } catch let CoreDataStackObjectModelLoadError.emptyModel(name, bundle) {
            XCTAssertEqual(name, emptyTestModelName)
            XCTAssertEqual(bundle, testBundle)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    // MARK: - persistentStoreCoordinator

    func testPersistentStoreCoordinator_WithValidInMemoryStoreTypeAndModel_ShouldSucceed() {

        let testStoreName = "test"

        let expectation = self.expectation(description: "persistentStoreCoordinator")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let storeLoadCompletion: (String, Error?) -> Void = { (storeName, error) in
            if let error = error {
                XCTFail("🔥: Test failed with error: \(error)")
            }
            expectation.fulfill()
        }

        let coordinator = MockCoreDataStack.persistentStoreCoordinator(withType: .inMemory,
                                                                       storeName: testStoreName,
                                                                       managedObjectModel: testManagedObjectModel,
                                                                       shouldAddStoreAsynchronously: false,
                                                                       shouldMigrateStoreAutomatically: true,
                                                                       shouldInferMappingModelAutomatically: true,
                                                                       storeLoadCompletionHandler: storeLoadCompletion)

        XCTAssertEqual(coordinator.persistentStores.count, 1)

        guard let store = coordinator.persistentStores.first else { return }

        XCTAssertEqual(store.type, NSInMemoryStoreType)
        XCTAssertEqual(store.identifier, testStoreName)
    }

    func testPersistentStoreCoordinator_WithValidSQLiteStoreTypeAndModel_ShouldSucceed() {

        let testStoreName = "test"
        let testStoreURL = libraryDirectory.appendingPathComponent("testStore.sqlite")

        let expectation = self.expectation(description: "persistentStoreCoordinator")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let storeLoadCompletion: (String, Error?) -> Void = { (storeName, error) in
            if let error = error {
                XCTFail("🔥: Test failed with error: \(error)")
            }
            expectation.fulfill()
        }

        let coordinator = MockCoreDataStack.persistentStoreCoordinator(withType: .sqLite(storeURL: testStoreURL),
                                                                       storeName: testStoreName,
                                                                       managedObjectModel: testManagedObjectModel,
                                                                       shouldAddStoreAsynchronously: false,
                                                                       shouldMigrateStoreAutomatically: true,
                                                                       shouldInferMappingModelAutomatically: true,
                                                                       storeLoadCompletionHandler: storeLoadCompletion)

        XCTAssertEqual(coordinator.persistentStores.count, 1)

        guard let store = coordinator.persistentStores.first else { return }

        XCTAssertEqual(store.type, NSSQLiteStoreType)
        XCTAssertEqual(store.url, testStoreURL)
        XCTAssertEqual(store.identifier, testStoreName)
    }

    func testPersistentStoreCoordinator_WithNonAccessibleSQLiteStoreURLAndValidModel_ShouldFailWithFailureToCreateFile() {

        let nonAccessibleStoreURL = URL(fileURLWithPath: "/var/non-accessible-store.sqlite")

        let expectation = self.expectation(description: "persistentStoreCoordinator")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let storeLoadCompletion: (String, Error?) -> Void = { (storeName, error) in
            if let error = error {
                XCTAssertEqual(error._domain, NSCocoaErrorDomain)
                XCTAssertEqual(error._code, NSFileWriteNoPermissionError)
            } else {
                XCTFail("🔥: Test failed with unexpected success!")
            }
            expectation.fulfill()
        }

        let coordinator = MockCoreDataStack.persistentStoreCoordinator(withType: .sqLite(storeURL: nonAccessibleStoreURL),
                                                                       storeName: "",
                                                                       managedObjectModel: testManagedObjectModel,
                                                                       shouldAddStoreAsynchronously: false,
                                                                       shouldMigrateStoreAutomatically: true,
                                                                       shouldInferMappingModelAutomatically: true,
                                                                       storeLoadCompletionHandler: storeLoadCompletion)

        XCTAssert(coordinator.persistentStores.isEmpty)
    }

    // TODO: Test Core Data model migrations on persistentStoreCoordinator 💪

    // MARK: - persistentContainer

    func testPersistentContainer_WithValidInMemoryStoreTypeAndModel_ShouldSucceed() {

        let testContainerName = "test"

        let expectation = self.expectation(description: "persistentStoreCoordinator")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let storeLoadCompletion: (NSPersistentStoreDescription, Error?) -> Void = { (store, error) in
            if let error = error {
                XCTFail("🔥: Test failed with error: \(error)")
            }
            expectation.fulfill()
        }

        let container = MockCoreDataStack.persistentContainer(withType: .inMemory,
                                                              name: testContainerName,
                                                              managedObjectModel: testManagedObjectModel,
                                                              shouldAddStoreAsynchronously: false,
                                                              shouldMigrateStoreAutomatically: true,
                                                              shouldInferMappingModelAutomatically: true,
                                                              storeLoadCompletionHandler: storeLoadCompletion)

        XCTAssertEqual(container.persistentStoreDescriptions.count, 1)
        XCTAssertEqual(container.name, testContainerName)

        guard let storeDescription = container.persistentStoreDescriptions.first else { return }

        XCTAssertEqual(storeDescription.type, NSInMemoryStoreType)
    }

    func testPersistentContainer_WithValidSQLiteStoreTypeAndModel_ShouldSucceed() {

        let testContainerName = "test"
        let testStoreURL = libraryDirectory.appendingPathComponent("testStore.sqlite")

        let expectation = self.expectation(description: "persistentStoreCoordinator")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let storeLoadCompletion: (NSPersistentStoreDescription, Error?) -> Void = { (store, error) in
            if let error = error {
                XCTFail("🔥: Test failed with error: \(error)")
            }
            expectation.fulfill()
        }

        let container = MockCoreDataStack.persistentContainer(withType: .sqLite(storeURL: testStoreURL),
                                                              name: testContainerName,
                                                              managedObjectModel: testManagedObjectModel,
                                                              shouldAddStoreAsynchronously: false,
                                                              shouldMigrateStoreAutomatically: true,
                                                              shouldInferMappingModelAutomatically: true,
                                                              storeLoadCompletionHandler: storeLoadCompletion)

        XCTAssertEqual(container.persistentStoreDescriptions.count, 1)
        XCTAssertEqual(container.name, testContainerName)

        guard let storeDescription = container.persistentStoreDescriptions.first else { return }

        XCTAssertEqual(storeDescription.type, NSSQLiteStoreType)
    }

    func testPersistentContainer_WithNonAccessibleSQLiteStoreURLAndValidModel_ShouldFailWithFailureToCreateFile() {

        let nonAccessibleStoreURL = URL(fileURLWithPath: "/var/non-accessible-store.sqlite")

        let expectation = self.expectation(description: "persistentStoreCoordinator")
        defer { waitForExpectations(timeout: expectationTimeout, handler: expectationHandler) }

        let storeLoadCompletion: (NSPersistentStoreDescription, Error?) -> Void = { (storeName, error) in
            if let error = error {
                XCTAssertEqual(error._domain, NSCocoaErrorDomain)
                XCTAssertEqual(error._code, NSFileWriteNoPermissionError)
            } else {
                XCTFail("🔥: Test failed with unexpected success!")
            }
            expectation.fulfill()
        }

        let _ = MockCoreDataStack.persistentContainer(withType: .sqLite(storeURL: nonAccessibleStoreURL),
                                                      name: "",
                                                      managedObjectModel: testManagedObjectModel,
                                                      shouldAddStoreAsynchronously: false,
                                                      shouldMigrateStoreAutomatically: true,
                                                      shouldInferMappingModelAutomatically: true,
                                                      storeLoadCompletionHandler: storeLoadCompletion)
    }

    // TODO: Test Core Data model migrations on persistentContainer 💪

    // MARK: - fetchedResultsController

    func testFetchedResultsController_WithGivenContextType_ShouldHaveCorrectContext() {

        let coreDataStack = MockCoreDataStack(storeType: .inMemory,
                                              storeName: "test",
                                              managedObjectModel: testManagedObjectModel)

        let testFetchRequest: NSFetchRequest<TestEntity> = TestEntity.fetchRequest()
        testFetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let workFetchedResultsController = coreDataStack.fetchedResultsController(fetchRequest: testFetchRequest,
                                                                                  sectionNameKeyPath: nil,
                                                                                  cacheName: nil,
                                                                                  contextType: .work)

        XCTAssertEqual(workFetchedResultsController.managedObjectContext, coreDataStack.context(withType: .work))

        let backgroundFetchedResultsController = coreDataStack.fetchedResultsController(fetchRequest: testFetchRequest,
                                                                                        sectionNameKeyPath: nil,
                                                                                        cacheName: nil,
                                                                                        contextType: .background)

        XCTAssertEqual(backgroundFetchedResultsController.managedObjectContext,
                       coreDataStack.context(withType: .background))
    }

    func testFetchedResultsController_WithGivenFetchRequestAndSectionAndCache_ShouldHaveCorrectValues() {

        let coreDataStack = MockCoreDataStack(storeType: .inMemory,
                                              storeName: "test",
                                              managedObjectModel: testManagedObjectModel)

        let testSectionNameKeyPath = "name"
        let testFetchRequest: NSFetchRequest<TestEntity> = TestEntity.fetchRequest()
        testFetchRequest.sortDescriptors = [NSSortDescriptor(key: testSectionNameKeyPath, ascending: true)]
        let testCacheName = "testCache"

        let fetchedResultsController = coreDataStack.fetchedResultsController(
            fetchRequest: testFetchRequest,
            sectionNameKeyPath: testSectionNameKeyPath,
            cacheName: testCacheName,
            contextType: .work)

        XCTAssertEqual(fetchedResultsController.fetchRequest, testFetchRequest)
        XCTAssertEqual(fetchedResultsController.sectionNameKeyPath, testSectionNameKeyPath)
        XCTAssertEqual(fetchedResultsController.cacheName, testCacheName)
    }
}

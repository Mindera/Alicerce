import XCTest
@testable import Alicerce

class NSManagedObjectContext_CoreDataStackTestCase: XCTestCase {

    enum MockError: Error { case 💩 }

    typealias ContextClosure<T> = () throws -> T
    typealias ContextCompletionClosure<T> = (T?, Error?) -> Void

    private let testModelName = "CoreDataStackModel"

    private var testBundle: Bundle {
        return Bundle(for: type(of: self))
    }

    private var testManagedObjectModel: NSManagedObjectModel {
        return try! MockCoreDataStack.managedObjectModel(withModelName: testModelName, in: testBundle)
    }

    private var libraryDirectory: URL {
        return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
    }

    private var testContext: MockManagedObjectContext!
    private var testParentContext: MockManagedObjectContext!

    override func setUp() {

        super.setUp()

        let coordinator = MockCoreDataStack.persistentStoreCoordinator(withType: .inMemory,
                                                                       storeName: "test",
                                                                       managedObjectModel: testManagedObjectModel)

        testParentContext = MockManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        testParentContext.persistentStoreCoordinator = coordinator

        testContext = MockManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        testContext.parent = testParentContext
    }

    override func tearDown() {

        testContext = nil
        testParentContext = nil

        super.tearDown()
    }

    // MARK: performThrowing

    func testPerformThrowing_WithNonThrowingClosure_ShouldInvokeCompletionWithReturnValue() {

        let closureExpectation = expectation(description: "closure")
        let completionExpectation = expectation(description: "completion")
        defer { waitForExpectations(timeout: 1) }

        let testValue = 1337

        let closure: ContextClosure<Int> = {

            closureExpectation.fulfill()
            return testValue
        }

        let completion: ContextCompletionClosure<Int> = { value, error in

            XCTAssertEqual(value, testValue)
            XCTAssertNil(error)
            completionExpectation.fulfill()
        }

        testContext.performThrowing(closure, completion: completion)
    }

    func testPerformThrowing_WithThrowingClosure_ShouldInvokeCompletionWithThrownError() {

        let closureExpectation = expectation(description: "closure")
        let completionExpectation = expectation(description: "completion")
        defer { waitForExpectations(timeout: 1) }

        let closure: ContextClosure<Int> = {

            closureExpectation.fulfill()
            throw MockError.💩
        }

        let completion: ContextCompletionClosure<Int> = { value, error in

            XCTAssertNil(value)
            XCTAssertDumpsEqual(error, MockError.💩)
            completionExpectation.fulfill()
        }

        testContext.performThrowing(closure, completion: completion)
    }

    // MARK: performThrowingAndWait

    func testPerformThrowingAndWait_WithNonThrowingClosure_ShouldReturnValue() {

        let testValue = 1337

        do {
            let value = try testContext.performThrowingAndWait { testValue }
            
            XCTAssertEqual(value, testValue)
        } catch {
            XCTFail("🔥: unexpected error: \(error)!")
        }
    }

    func testPerformThrowingAndWait_WithThrowingClosure_ShouldThrowError() {

        do {
            let _ = try testContext.performThrowingAndWait { throw MockError.💩 }

            XCTFail("🔥: unexpected success!")
        } catch MockError.💩 {
            // expected error
        } catch {
            XCTFail("🔥: unexpected error: \(error)!")
        }
    }

    // MARK: persistChanges

    func testPersistChanges_WithNoParentAndNoChanges_ShouldReturnEarly() {

        testParentContext.didInvokeSave = { XCTFail("🔥: unexpected save!") }
        testParentContext.didInvokeRollBack = { XCTFail("🔥: unexpected rollback!") }

        do {
            try testContext.persistChanges("no parent + no changes", saveParent: false, waitForParent: false)
        } catch {
            XCTFail("🔥: unexpected error: \(error)!")
        }
    }

    func testPersistChanges_WithNoParentAndChanges_ShouldSave() {

        let saveExpectation = expectation(description: "save")
        defer { waitForExpectations(timeout: 1) }

        testParentContext.didInvokeSave = { saveExpectation.fulfill() }
        testParentContext.didInvokeRollBack = { XCTFail("🔥: unexpected rollback!") }

        createDummyInstance(in: testParentContext)

        do {
            try testParentContext.persistChanges("no parent + changes", saveParent: false, waitForParent: false)
        } catch {
            XCTFail("🔥: unexpected error: \(error)!")
        }
    }

    func testPersistChanges_WithNoParentAndChangesAndSaveError_ShouldThrowAndRollback() {

        let saveExpectation = expectation(description: "save")
        let rollbackExpectation = expectation(description: "rollback")
        defer { waitForExpectations(timeout: 1) }

        testParentContext.didInvokeSave = { saveExpectation.fulfill() }
        testParentContext.didInvokeRollBack = { rollbackExpectation.fulfill() }
        testParentContext.mockSaveError = MockError.💩

        createDummyInstance(in: testParentContext)

        do {
            try testParentContext.persistChanges("no parent + changes + save error",
                                                 saveParent: false,
                                                 waitForParent: false)
        } catch MockError.💩 {
            // expected error
        } catch {
            XCTFail("🔥: unexpected error: \(error)!")
        }
    }

    func testPersistChanges_WithParentAndChangesAndNoSaveParent_ShouldSaveInChildContext() {

        let saveExpectation = expectation(description: "save")
        defer { waitForExpectations(timeout: 1) }

        testContext.didInvokeSave = { saveExpectation.fulfill() }
        testContext.didInvokeRollBack = { XCTFail("🔥: unexpected rollback!") }

        testParentContext.didInvokeSave = { XCTFail("🔥: unexpected parent save!") }
        testParentContext.didInvokeRollBack = { XCTFail("🔥: unexpected parent rollback!") }

        createDummyInstance(in: testContext)

        do {
            try testContext.persistChanges("changes + parent + no save parent", saveParent: false, waitForParent: false)
        } catch {
            XCTFail("🔥: unexpected error: \(error)!")
        }
    }

    func testPersistChanges_WithParentAndChangesAndSaveParentAndWaitForParent_ShouldSaveInBothContextsAndWait() {

        let saveExpectation = expectation(description: "save")
        let saveParentExpectation = expectation(description: "save parent")
        let performAndWaitParentExpectation = expectation(description: "performAndWait parent")
        defer { waitForExpectations(timeout: 1) }

        testContext.didInvokeSave = { saveExpectation.fulfill() }
        testContext.didInvokeRollBack = { XCTFail("🔥: unexpected rollback!") }

        testParentContext.didInvokeSave = { saveParentExpectation.fulfill() }
        testParentContext.didInvokeRollBack = { XCTFail("🔥: unexpected parent rollback!") }
        testParentContext.didInvokePerform = { XCTFail("🔥: unexpected parent perform!") }
        testParentContext.didInvokePerformAndWait = { performAndWaitParentExpectation.fulfill() }

        createDummyInstance(in: testContext)

        do {
            try testContext.persistChanges("changes + parent + save parent + wait for parent",
                                           saveParent: true,
                                           waitForParent: true)
        } catch {
            XCTFail("🔥: unexpected error: \(error)!")
        }
    }

    func testPersistChanges_WithParentAndChangesAndSaveParentAndNoWaitForParent_ShouldSaveInBothContextsAndNotWait() {

        let saveExpectation = expectation(description: "save")
        let saveParentExpectation = expectation(description: "save parent")
        let performParentExpectation = expectation(description: "perform parent")
        defer { waitForExpectations(timeout: 1) }

        testContext.didInvokeSave = { saveExpectation.fulfill() }
        testContext.didInvokeRollBack = { XCTFail("🔥: unexpected rollback!") }

        testParentContext.didInvokeSave = { saveParentExpectation.fulfill() }
        testParentContext.didInvokeRollBack = { XCTFail("🔥: unexpected parent rollback!") }
        testParentContext.didInvokePerform = { performParentExpectation.fulfill() }
        testParentContext.didInvokePerformAndWait = { XCTFail("🔥: unexpected parent performAndWait!") }

        createDummyInstance(in: testContext)

        do {
            try testContext.persistChanges("changes + parent + save parent + no wait for parent",
                                           saveParent: true,
                                           waitForParent: false)
        } catch {
            XCTFail("🔥: unexpected error: \(error)!")
        }
    }

    func testPersistChanges_WithParentAndChangesAndSaveParentAndWaitForParentAndParentSaveError_ShouldSaveInChildAndRollbackParentAndThrow() {

        let saveExpectation = expectation(description: "save")
        let saveParentExpectation = expectation(description: "save parent")
        let rollbackParentExpectation = expectation(description: "rollback parent")
        let performAndWaitParentExpectation = expectation(description: "performAndWait parent")
            performAndWaitParentExpectation.expectedFulfillmentCount = 3 // one on save and two more on rollback
        defer { waitForExpectations(timeout: 1) }

        testContext.didInvokeSave = { saveExpectation.fulfill() }
        testContext.didInvokeRollBack = { XCTFail("🔥: unexpected rollback!") }

        testParentContext.didInvokeSave = { saveParentExpectation.fulfill() }
        testParentContext.didInvokeRollBack = { rollbackParentExpectation.fulfill() }
        testParentContext.didInvokePerform = { XCTFail("🔥: unexpected parent perform!") }
        testParentContext.didInvokePerformAndWait = { performAndWaitParentExpectation.fulfill() }
        testParentContext.mockSaveError = MockError.💩

        createDummyInstance(in: testContext)

        do {
            try testContext.persistChanges("changes + parent + save parent + wait for parent",
                                           saveParent: true,
                                           waitForParent: true)
        } catch MockError.💩 {
            // expected error
        } catch {
            XCTFail("🔥: unexpected error: \(error)!")
        }
    }

    // MARK: topLevelPersistentStoreCoordinator

    func testTopLevelPersistentStoreCoordinator_WithCoordinator_ShouldReturnIt() {

        XCTAssertNotNil(testParentContext.persistentStoreCoordinator)
        XCTAssertNil(testParentContext.parent)
        XCTAssertEqual(testParentContext.topLevelPersistentStoreCoordinator,
                       testParentContext.persistentStoreCoordinator)
    }

    func testTopLevelPersistentStoreCoordinator_WithParentWithCoordinator_ShouldReturnParentCoordinator() {

        XCTAssertNotNil(testContext.parent)
        XCTAssertNotNil(testContext.persistentStoreCoordinator) // propagated from parent, not explicitly set
        XCTAssertEqual(testContext.topLevelPersistentStoreCoordinator,
                       testContext.persistentStoreCoordinator)
        XCTAssertEqual(testParentContext.topLevelPersistentStoreCoordinator,
                       testContext.topLevelPersistentStoreCoordinator)
    }

    func testTopLevelPersistentStoreCoordinator_WithNoCoordinatorAndNoParent_ShouldReturnNil() {

        let context = MockManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

        XCTAssertNil(context.persistentStoreCoordinator)
        XCTAssertNil(context.parent)
        XCTAssertNil(context.topLevelPersistentStoreCoordinator)
    }

    // MARK: isSQLiteStoreBased

    func testIsSQLiteStoreBased_WithInMemoryBasedPersistentStoreCoordinator_ShouldReturnFalse() {

        XCTAssertNotNil(testParentContext.persistentStoreCoordinator)
        XCTAssertFalse(testParentContext.isSQLiteStoreBased)
    }

    func testIsSQLiteStoreBased_WithInMemoryBasedParentPersistentStoreCoordinator_ShouldReturnFalse() {

        XCTAssertNotNil(testContext.parent)
        XCTAssertEqual(testContext.parent, testParentContext)
        XCTAssertNotNil(testParentContext.persistentStoreCoordinator)
        XCTAssertFalse(testParentContext.isSQLiteStoreBased)
        XCTAssertFalse(testContext.isSQLiteStoreBased)
    }

    func testIsSQLiteStoreBased_WithSQLiteBasedPersistentStoreCoordinator_ShouldReturnTrue() {

        let testStoreURL = makeTestStoreURL(withName: "SQLiteBasedPersistentStoreCoordinator")
        defer { removeSQLiteStoreFiles(at: testStoreURL) }

        let coordinator = MockCoreDataStack.persistentStoreCoordinator(withType: .sqlite(storeURL: testStoreURL),
                                                                       storeName: "test",
                                                                       managedObjectModel: testManagedObjectModel)

        testParentContext = MockManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        testParentContext.persistentStoreCoordinator = coordinator

        testContext = MockManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        testContext.parent = testParentContext

        XCTAssertNotNil(testParentContext.persistentStoreCoordinator)
        XCTAssert(testParentContext.isSQLiteStoreBased)
    }

    func testIsSQLiteStoreBased_WithSQLiteBasedParentPersistentStoreCoordinator_ShouldReturnTrue() {

        let testStoreURL = makeTestStoreURL(withName: "SQLiteBasedParentPersistentStoreCoordinator")
        defer { removeSQLiteStoreFiles(at: testStoreURL) }

        let coordinator = MockCoreDataStack.persistentStoreCoordinator(withType: .sqlite(storeURL: testStoreURL),
                                                                       storeName: "test",
                                                                       managedObjectModel: testManagedObjectModel)

        testParentContext = MockManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        testParentContext.persistentStoreCoordinator = coordinator

        testContext = MockManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        testContext.parent = testParentContext

        XCTAssertNotNil(testContext.parent)
        XCTAssertEqual(testContext.parent, testParentContext)
        XCTAssertNotNil(testParentContext.persistentStoreCoordinator)
        XCTAssert(testParentContext.isSQLiteStoreBased)
        XCTAssert(testContext.isSQLiteStoreBased)


    }

    func testIsSQLiteStoreBased_WithNoCoordinatorAndNoParent_ShouldReturnFalse() {

        let context = MockManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

        XCTAssertNil(context.persistentStoreCoordinator)
        XCTAssertNil(context.parent)
        XCTAssertFalse(context.isSQLiteStoreBased)
    }

    // Auxiliary

    private func createDummyInstance(in context: NSManagedObjectContext) {

        context.performAndWait { let _ = TestEntity(in: context, id: 1337, name: nil) }
    }

    private func makeTestStoreURL(withName name: String) -> URL {
        return libraryDirectory.appendingPathComponent("\(name).sqlite")
    }

    private func removeSQLiteStoreFiles(at storeURL: URL) {

        do {
            let fm = FileManager.default
            try fm.removeItem(at: storeURL)

            // Remove journal files if present
            try? fm.removeItem(at: storeURL.appendingPathComponent("-shm"))
            try? fm.removeItem(at: storeURL.appendingPathComponent("-wal"))
        } catch {
            XCTFail("🔥: Failed to delete SQLite store! Error: \(error)")
        }
    }
}

final private class MockManagedObjectContext: NSManagedObjectContext {

    var didInvokePerform: (() -> Void)? = nil
    var didInvokePerformAndWait: (() -> Void)? = nil

    var didInvokeSave: (() -> Void)? = nil
    var didInvokeRollBack: (() -> Void)? = nil

    var mockSaveError: Error? = nil

    override func perform(_ block: @escaping () -> Void) {

        didInvokePerform?()
        super.perform(block)
    }

    override func performAndWait(_ block: () -> Void) {

        didInvokePerformAndWait?()
        super.performAndWait(block)
    }

    override func save() throws {

        didInvokeSave?()

        if let mockSaveError = mockSaveError {
            throw mockSaveError
        }

        try super.save()
    }

    override func rollback() {

        didInvokeRollBack?()
        super.rollback()
    }

}

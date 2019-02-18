import XCTest
@testable import Alicerce

class CoreDataStack_ManagedObjectReflectableTestCase: XCTestCase {

    enum MockError: Error { case 💣, 🧨 }

    typealias TransformClosure<Internal, External> = (Internal) throws -> External
    typealias CreateClosure<Internal, External> = (NSManagedObjectContext) throws -> ([Internal], [External])
    typealias UpdateClosure<Internal, External> = (Internal) throws -> External
    typealias FilterAndCreateClosure<Internal, External> =
        ([Internal], NSManagedObjectContext) throws -> ([Internal], [External])

    private var coreDataStack: MockCoreDataStack!
    private var testValue: TestEntityValue!

    private var testBundle: Bundle {
        return Bundle(for: type(of: self))
    }

    private lazy var managedObjectModel: NSManagedObjectModel = {
        return try! MockCoreDataStack.managedObjectModel(withModelName: "CoreDataStackModel", in: self.testBundle)
    }()

    override func setUp() {

        super.setUp()

        coreDataStack = MockCoreDataStack(storeType: .inMemory,
                                          storeName: "test",
                                          managedObjectModel: managedObjectModel)

        testValue = TestEntityValue(id: 1337, name: "😎")
    }

    override func tearDown() {

        coreDataStack = nil
        testValue = nil

        TestEntityValue.didInvokeInit = nil
        TestEntityValue.didInvokeFilter = nil
        
        super.tearDown()
    }

    // MARK: exists

    func testExists_WithExistingObject_ShouldReturnTrue() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!

        do { testEntityObjectID = try testContext.createTestEntity(value: testValue) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        // test
        do {
            let testExists = try coreDataStack.exists(TestEntityValue.self,
                                                      predicate: .id(testValue.id),
                                                      contextType: .work)

            XCTAssertTrue(testExists)
            testContext.validateTestEntity(with: testEntityObjectID, equals: testValue)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testExists_WithNonExistingObject_ShouldReturnFalse() {

        do {
            let testExists = try coreDataStack.exists(TestEntityValue.self,
                                                      predicate: .id(testValue.id),
                                                      contextType: .work)

            XCTAssertFalse(testExists)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testExists_WithThrowingManagedObjectContext_ShouldThrowError() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: MockError.💣)

        do {
            let _ = try coreDataStack.exists(TestEntityValue.self, predicate: .id(testValue.id), contextType: .work)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.💣 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    // MARK: fetch

    func testFetch_WithMatchingPredicate_ShouldReturnMatches() {

        let testContext = coreDataStack.context(withType: .work)

        do { let _ = try testContext.createTestEntity(value: testValue) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        do {
            let values = try coreDataStack.fetch(TestEntityValue.self,
                                                 with: .id(testValue.id),
                                                 contextType: .work)

            XCTAssertEqual(values, [testValue])
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testFetch_WithNonMatchingPredicate_ShouldReturnNoMatches() {

        let testContext = coreDataStack.context(withType: .work)

        do { let _ = try testContext.createTestEntity(value: testValue) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        do {
            let values = try coreDataStack.fetch(TestEntityValue.self, with: .id(0), contextType: .work)

            XCTAssert(values.isEmpty)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testFetch_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: MockError.💣)

        do {
            let _ = try coreDataStack.fetch(TestEntityValue.self, with: .id(testValue.id), contextType: .work)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.💣 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    // MARK: findOrCreate

    func testFindOrCreate_WithNonExistingObject_ShouldCreateIt() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!

        TestEntityValue.didInvokeFilter = { existingObjects, newValues in

            XCTAssert(existingObjects.isEmpty)
            XCTAssertEqual(newValues, [self.testValue])
        }

        testValue.didInvokeReflect = { object in

            try! testContext.obtainPermanentIDs(for: [object])
            testEntityObjectID = object.objectID
        }

        do {
            let values = try coreDataStack.findOrCreate(with: .id(testValue.id),
                                                        entities: [testValue],
                                                        contextType: .work)

            XCTAssertEqual(values, [testValue])
            testContext.validateTestEntity(with: testEntityObjectID, equals: testValue)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testFindOrCreate_WithExistingObject_ShouldReturnIt() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!

        do { testEntityObjectID = try testContext.createTestEntity(value: testValue) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        TestEntityValue.didInvokeFilter = { existingObjects, newValues in

            XCTAssertEqual(existingObjects.count, 1)
            XCTAssertEqual(existingObjects.first?.objectID, testEntityObjectID)
            XCTAssertEqual(newValues, [self.testValue])
        }

        testValue.didInvokeReflect = { object in

            try! testContext.obtainPermanentIDs(for: [object])
            testEntityObjectID = object.objectID
        }

        do {
            let values = try coreDataStack.findOrCreate(with: .id(testValue.id),
                                                        entities: [testValue],
                                                        contextType: .work)

            XCTAssertEqual(values, [testValue])
            testContext.validateTestEntity(with: testEntityObjectID, equals: testValue)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testFindOrCreate_WithExistingAndNonExistingObjects_ShouldFetchOneAndCreateAnother() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!

        var testNewEntityObjectID: NSManagedObjectID!
        var testNewValue = TestEntityValue(id: 7331, name: "🙃")

        do { testEntityObjectID = try testContext.createTestEntity(value: testValue) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        TestEntityValue.didInvokeFilter = { existingObjects, newValues in

            XCTAssertEqual(existingObjects.count, 1)
            XCTAssertEqual(existingObjects.first?.objectID, testEntityObjectID)
            XCTAssertEqual(newValues, [testNewValue])
        }

        testNewValue.didInvokeReflect = { object in

            // reflect new entity
            try! testContext.obtainPermanentIDs(for: [object])
            testNewEntityObjectID = object.objectID
        }

        TestEntityValue.didInvokeInit = { object in

            // reflect existing entity
            XCTAssertEqual(object.objectID, testEntityObjectID)
        }

        do {
            let predicate = NSPredicate(format: "id in %@", [testValue.id, testNewValue.id])
            let values = try coreDataStack.findOrCreate(with: predicate, entities: [testNewValue], contextType: .work)

            // order is created + updated, but we could compare two Set's
            XCTAssertEqual(values, [testNewValue, testValue])
            testContext.validateTestEntity(with: testNewEntityObjectID, equals: testNewValue)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testFindOrCreate_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: MockError.🧨)

        do {
            let _ = try coreDataStack.findOrCreate(with: .id(testValue.id), entities: [testValue], contextType: .work)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.🧨 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    // MARK: create

    func testCreate_WithValidValueAndNonThrowingCreateClosure_ShouldSucceed() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!

        testValue.didInvokeReflect = { object in

            // reflect new entity
            try! testContext.obtainPermanentIDs(for: [object])
            testEntityObjectID = object.objectID
        }

        do {
            try coreDataStack.create([testValue], contextType: .work)

            testContext.validateTestEntity(with: testEntityObjectID, equals: testValue)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCreate_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: MockError.🧨)

        do {
            let _ = try coreDataStack.create([testValue], contextType: .work)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.🧨 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    // MARK: createOrUpdate

    func testCreateOrUpdate_WithNonExistingObject_ShouldCreateIt() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!

        TestEntityValue.didInvokeFilter = { existingObjects, newValues in

            XCTAssert(existingObjects.isEmpty)
            XCTAssertEqual(newValues, [self.testValue])
        }

        testValue.didInvokeReflect = { object in

            // reflect new entity
            try! testContext.obtainPermanentIDs(for: [object])
            testEntityObjectID = object.objectID
        }

        TestEntityValue.didInvokeInit = { _ in

            // reflect existing entity
            XCTFail("🔥: unexpected existing entity reflection!")
        }

        let update: (TestEntityValue) -> TestEntityValue = { value in

            XCTFail("🔥: unexpected update!")
            return value
        }

        do {
            let values = try coreDataStack.createOrUpdate(with: .id(testValue.id),
                                                          contextType: .work,
                                                          entities: [testValue],
                                                          update: update)

            XCTAssertEqual(values, [testValue])
            testContext.validateTestEntity(with: testEntityObjectID, equals: testValue)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCreateOrUpdate_WithExistingObject_ShouldUpdateAndReturnIt() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!

        var testUpdatedValue = testValue!
        testUpdatedValue.name = "🤩"

        do { testEntityObjectID = try testContext.createTestEntity(value: testValue) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        TestEntityValue.didInvokeFilter = { existingObjects, newValues in

            XCTAssertEqual(existingObjects.count, 1)
            XCTAssertEqual(existingObjects.first?.objectID, testEntityObjectID)
            XCTAssertEqual(newValues, [self.testValue])
        }

        testValue.didInvokeReflect = { _ in

            // reflect new entity
            XCTFail("🔥: unexpected new entity reflection!")
        }

        TestEntityValue.didInvokeInit = { object in

            // reflect existing entity
            XCTAssertEqual(object.objectID, testEntityObjectID)
        }

        let update: (TestEntityValue) -> TestEntityValue = { value in

            XCTAssertEqual(value, self.testValue)
            return testUpdatedValue
        }

        do {
            let values = try coreDataStack.createOrUpdate(with: .id(testValue.id),
                                                          contextType: .work,
                                                          entities: [testValue],
                                                          update: update)

            XCTAssertEqual(values, [testUpdatedValue])

            testContext.validateTestEntity(with: testEntityObjectID, equals: testUpdatedValue)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCreateOrUpdate_WithExistingAndNonExistingObjects_ShouldUpdateOneAndCreateAnother() {

        let testContext = coreDataStack.context(withType: .work)

        var testEntityObjectID: NSManagedObjectID!

        var testUpdatedValue = testValue!
        testUpdatedValue.name = "🤩"

        var testNewEntityObjectID: NSManagedObjectID!
        var testNewValue = TestEntityValue(id: 7331, name: "🙃")

        do { testEntityObjectID = try testContext.createTestEntity(value: testValue) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        TestEntityValue.didInvokeFilter = { existingObjects, newValues in

            XCTAssertEqual(existingObjects.count, 1)
            XCTAssertEqual(existingObjects.first?.objectID, testEntityObjectID)
            XCTAssertEqual(newValues, [testNewValue])
        }

        testNewValue.didInvokeReflect = { object in

            // reflect new entity
            try! testContext.obtainPermanentIDs(for: [object])
            testNewEntityObjectID = object.objectID
        }

        TestEntityValue.didInvokeInit = { object in

            // reflect existing entity
            XCTAssertEqual(object.objectID, testEntityObjectID)
        }

        let update: (TestEntityValue) -> TestEntityValue = { value in

            XCTAssertEqual(value, self.testValue)
            return testUpdatedValue
        }

        do {
            let predicate = NSPredicate(format: "id in %@", [testValue.id, testNewValue.id])
            let values = try coreDataStack.createOrUpdate(with: predicate,
                                                          contextType: .work,
                                                          entities: [testNewValue],
                                                          update: update)

            XCTAssertEqual(values, [testNewValue, testUpdatedValue])
            testContext.validateTestEntity(with: testEntityObjectID, equals: testUpdatedValue)
            testContext.validateTestEntity(with: testNewEntityObjectID, equals: testNewValue)

        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCreateOrUpdate_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: MockError.🧨)

        let update: (TestEntityValue) -> TestEntityValue = { value in

            XCTFail("🔥: unexpected update!")
            return value
        }

        do {
            let _ = try coreDataStack.createOrUpdate(with: .id(testValue.id),
                                                     contextType: .work,
                                                     entities: [testValue],
                                                     update: update)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.🧨 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    // MARK: update

    func testUpdate_WithExistingObjectsAndNonThrowingUpdateClosure_ShouldUpdateMatches() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!

        var testUpdatedValue = testValue!
        testUpdatedValue.name = "🤩"

        do { testEntityObjectID = try testContext.createTestEntity(value: testValue) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let update: (TestEntityValue) -> TestEntityValue = { value in

            XCTAssertEqual(value, self.testValue)
            return testUpdatedValue
        }

        do {
            let values = try coreDataStack.update(TestEntityValue.self,
                                                  with: .id(testValue.id),
                                                  contextType: .work,
                                                  update: update)

            XCTAssertEqual(values, [testUpdatedValue])
            testContext.validateTestEntity(with: testEntityObjectID, equals: testUpdatedValue)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testUpdate_WithNonExistingObjects_ShouldReturnNoMatches() {

        let update: (TestEntityValue) -> TestEntityValue = { value in

            XCTFail("🔥: unexpected update!")
            return value
        }

        do {
            let values = try coreDataStack.update(TestEntityValue.self,
                                                  with: .id(testValue.id),
                                                  contextType: .work,
                                                  update: update)

            XCTAssert(values.isEmpty)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testUpdate_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: MockError.🧨)

        let update: (TestEntityValue) -> TestEntityValue = { value in

            XCTFail("🔥: unexpected update!")
            return value
        }

        do {
            let _ = try coreDataStack.update(TestEntityValue.self,
                                             with: .id(testValue.id),
                                             contextType: .work,
                                             update: update)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.🧨 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    // MARK: delete

    func testDelete_WithExistingObjectsAndNoCleanupClosure_ShouldDeleteThem() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!

        do { testEntityObjectID = try testContext.createTestEntity(value: testValue) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        do {
            let deleted = try coreDataStack.delete(TestEntityValue.self,
                                                   predicate: .id(testValue.id),
                                                   contextType: .work)

            XCTAssertEqual(deleted, 1)

            testContext.validateTestEntity(with: testEntityObjectID) { entity in
                if let _ = entity { XCTFail("🔥: unexpected existent entity!") }
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testDelete_WithSQLiteStoreAndExistingObjectsAndNoCleanupClosure_ShouldDeleteThem() {

        // Test the codepath where `delete` uses a `NSBatchDeleteRequest` (only available on SQLite stores)
        let libraryDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let testStoreURL = libraryDirectory.appendingPathComponent("testMORBatchDeleteStore.sqlite")

        defer {
            do {
                let fm = FileManager.default
                try fm.removeItem(at: testStoreURL)

                // Remove journal files if present
                try? fm.removeItem(at: testStoreURL.appendingPathComponent("-shm"))
                try? fm.removeItem(at: testStoreURL.appendingPathComponent("-wal"))
            }
            catch { XCTFail("🔥: Failed to delete SQLite store! Error: \(error)") }
        }

        let sqLiteCoreDataStack = MockCoreDataStack(storeType: .sqLite(storeURL: testStoreURL),
                                                    storeName: "test",
                                                    managedObjectModel: managedObjectModel)

        // setup
        let testContext = sqLiteCoreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!

        do { testEntityObjectID = try testContext.createTestEntity(value: testValue) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        do {
            let deleted = try sqLiteCoreDataStack.delete(TestEntityValue.self,
                                                         predicate: .id(testValue.id),
                                                         contextType: .work)

            XCTAssertEqual(deleted, 1)

            testContext.validateTestEntity(with: testEntityObjectID) { entity in
                if let existent = entity, existent.isDeleted == false { XCTFail("🔥: unexpected existent entity!") }
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testDelete_WithExistingObjectsAndCleanupClosure_ShouldCallCleanupAndThenDeleteThem() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!

        do { testEntityObjectID = try testContext.createTestEntity(value: testValue) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let cleanup: (TestEntityValue) -> Void = { value in

            XCTAssertEqual(value, self.testValue)
        }

        do {
            let deleted = try coreDataStack.delete(TestEntityValue.self,
                                                   predicate: .id(testValue.id),
                                                   contextType: .work,
                                                   cleanup: cleanup)

            XCTAssertEqual(deleted, 1)

            testContext.validateTestEntity(with: testEntityObjectID) { entity in
                if let _ = entity { XCTFail("🔥: unexpected existent entity!") }
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testDelete_WithNonExistingObject_ShouldDoNothing() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!

        do { testEntityObjectID = try testContext.createTestEntity(value: testValue) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        do {
            let deleted = try coreDataStack.delete(TestEntity.self, predicate: .id(0), contextType: .work)

            XCTAssertEqual(deleted, 0)
            testContext.validateTestEntity(with: testEntityObjectID, equals: testValue)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testDelete_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: MockError.🧨)

        do {
            let _ = try coreDataStack.delete(TestEntityValue.self, predicate: .id(testValue.id), contextType: .work)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.🧨 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    // MARK: count

    func testCount_WithMatchingObjects_ShouldReturnCount() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!

        do { testEntityObjectID = try testContext.createTestEntity(value: testValue) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        do {
            let count = try coreDataStack.count(TestEntityValue.self, with: .id(testValue.id), contextType: .work)

            XCTAssertEqual(count, 1)
            testContext.validateTestEntity(with: testEntityObjectID, equals: testValue)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCount_WithNonMatchingObjects_ShouldReturnZero() {

        do {
            let count = try coreDataStack.count(TestEntityValue.self, with: .id(testValue.id), contextType: .work)

            XCTAssertEqual(count, 0)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCount_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: MockError.🧨)

        do {
            let _ = try coreDataStack.count(TestEntityValue.self, with: .id(testValue.id), contextType: .work)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.🧨 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

}

import XCTest
import CoreData
@testable import Alicerce

extension MockErrorManagedObjectContext {

    convenience init(mockError: Error) {
        self.init(concurrencyType: .privateQueueConcurrencyType)
        self.mockError = mockError
    }
}

class CoreDataStack_CRUDTestCase: XCTestCase {

    enum MockError: Error { case 💥, 💩 }

    typealias TransformClosure<Internal, External> = (Internal) throws -> External
    typealias CreateClosure<Internal, External> = (NSManagedObjectContext) throws -> ([Internal], [External])
    typealias UpdateClosure<Internal, External> = (Internal) throws -> External
    typealias FilterAndCreateClosure<Internal, External> =
        ([Internal], NSManagedObjectContext) throws -> ([Internal], [External])

    private var coreDataStack: MockCoreDataStack!

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
    }
    
    override func tearDown() {
        coreDataStack = nil

        super.tearDown()
    }

    // MARK: exists

    func testExists_WithExistingEntity_ShouldReturnTrue() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!
        let testEntityID: Int64 = 1337
        do { testEntityObjectID = try testContext.createTestEntity(id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        // test
        do {
            let testExists = try coreDataStack.exists(TestEntity.self, predicate: .id(testEntityID), contextType: .work)

            XCTAssertTrue(testExists)

            testContext.validateTestEntity(with: testEntityObjectID) { entity in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testExists_WithNonExistingEntity_ShouldReturnFalse() {

        do {
            let testExists = try coreDataStack.exists(TestEntity.self, predicate: .id(1337), contextType: .work)

            XCTAssertFalse(testExists)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testExists_WithThrowingManagedObjectContext_ShouldThrowError() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: MockError.💥)

        do {
            let _ = try coreDataStack.exists(TestEntity.self, predicate: .name("💥"), contextType: .work)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    // MARK: fetch

    func testFetch_WithMatchingPredicate_ShouldReturnMatches() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!
        let testEntityID: Int64 = 1337
        let testEntityName: String = "test"
        do { testEntityObjectID = try testContext.createTestEntity(id: testEntityID, name: testEntityName) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let transform: TransformClosure<TestEntity, NSManagedObjectID> = { return $0.objectID }

        do {
            let objectIDs = try coreDataStack.fetch(with: .id(1337), contextType: .work, transform: transform)

            XCTAssertEqual(objectIDs.count, 1)
            XCTAssertTrue(objectIDs.contains(testEntityObjectID))
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testFetch_WithNonMatchingPredicate_ShouldReturnNoMatches() {

        let testEntityID: Int64 = 1337
        do { let _ = try coreDataStack.context(withType: .work).createTestEntity(id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let transform: TransformClosure<TestEntity, NSManagedObjectID> = { _ in throw MockError.💩 }

        do {
            let matches = try coreDataStack.fetch(with: .id(0), contextType: .work, transform: transform)

            XCTAssert(matches.isEmpty)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testFetch_WithMatchingPredicateAndThrowingTransformClosure_ShouldThrow() {

        let testEntityID: Int64 = 1337
        do { let _ = try coreDataStack.context(withType: .work).createTestEntity(id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let transform: TransformClosure<TestEntity, NSManagedObjectID> = { _ in throw MockError.💥 }

        do {
            let _ = try coreDataStack.fetch(with: .id(testEntityID), contextType: .work, transform: transform)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testFetch_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: MockError.💥)

        let transform: TransformClosure<TestEntity, NSManagedObjectID> = { _ in throw MockError.💩 }

        do {
            let _ = try coreDataStack.fetch(with: .id(1337), contextType: .work, transform: transform)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    // MARK: findOrCreate

    func testFindOrCreate_WithNonExistingEntity_ShouldCreateIt() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!
        let testEntityID: Int64 = 1337
        let testEntityName: String = "test"

        let filterExistingAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { existing, context in
            XCTAssertTrue(existing.isEmpty)

            let entity = TestEntity(in: testContext, id: testEntityID, name: testEntityName)
            try context.obtainPermanentIDs(for: [entity])
            testEntityObjectID = entity.objectID

            return ([entity], [entity.objectID])
        }

        let transform: TransformClosure<TestEntity, NSManagedObjectID> = { _ in throw MockError.💩 }

        do {
            let objectIDs = try coreDataStack.findOrCreate(with: .id(testEntityID),
                                                           contextType: .work,
                                                           filterExistingAndCreate: filterExistingAndCreate,
                                                           transform: transform)

            XCTAssertEqual(objectIDs.count, 1)
            XCTAssertTrue(objectIDs.contains(testEntityObjectID))

            testContext.validateTestEntity(with: testEntityObjectID) { entity in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
                XCTAssertEqual(entity.name, testEntityName)
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testFindOrCreate_WithNonExistingEntityAndThrowingFilterAndCreateClosure_ShouldThrow() {

        let filterExistingAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { _, _  in
            throw MockError.💥
        }
        let transform: TransformClosure<TestEntity, NSManagedObjectID> = { _ in throw MockError.💩 }

        do {
            let _ = try coreDataStack.findOrCreate(with: .id(1337),
                                                   contextType: .work,
                                                   filterExistingAndCreate: filterExistingAndCreate,
                                                   transform: transform)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testFindOrCreate_WithExistingEntity_ShouldReturnIt() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!
        let testEntityID: Int64 = 1337
        let testEntityName: String = "test"

        do { testEntityObjectID = try testContext.createTestEntity(id: testEntityID, name: testEntityName) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let filterExistingAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { existing, context in
            XCTAssertEqual(existing.count, 1)

            guard let first = existing.first else { return ([], []) }
            XCTAssertEqual(first.id, testEntityID)
            XCTAssertEqual(first.name, testEntityName)

            return ([], [])
        }
        let transform: TransformClosure<TestEntity, NSManagedObjectID> = { $0.objectID }

        do {
            let objectIDs = try coreDataStack.findOrCreate(with: .id(testEntityID),
                                                           contextType: .work,
                                                           filterExistingAndCreate: filterExistingAndCreate,
                                                           transform: transform)

            XCTAssertEqual(objectIDs.count, 1)
            XCTAssertTrue(objectIDs.contains(testEntityObjectID))
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testFindOrCreate_WithExistingEntityAndThrowingTransformClosure_ShouldThrow() {

        let testEntityID: Int64 = 1337
        do { let _ = try coreDataStack.context(withType: .work).createTestEntity(id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let filterExistingAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { existing, context in
            XCTAssertEqual(existing.count, 1)

            guard let first = existing.first else { return ([], []) }
            XCTAssertEqual(first.id, testEntityID)

            return ([], [])
        }
        let transform: TransformClosure<TestEntity, NSManagedObjectID> = { _ in throw MockError.💥 }

        do {
            let _ = try coreDataStack.findOrCreate(with: .id(testEntityID),
                                                   contextType: .work,
                                                   filterExistingAndCreate: filterExistingAndCreate,
                                                   transform: transform)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testFindOrCreate_WithExistingAndNonExistingEntities_ShouldFetchOneAndCreateAnother() {

        let testContext = coreDataStack.context(withType: .work)

        var testEntityObjectID: NSManagedObjectID!
        let testEntityID: Int64 = 1337
        let testEntityName: String = "test"

        var testNewEntityObjectID: NSManagedObjectID!
        let testNewEntityID: Int64 = 7331
        let testNewEntityName: String = "new"

        do { testEntityObjectID = try testContext.createTestEntity(id: testEntityID, name: testEntityName) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let filterExistingAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { existing, context in
            XCTAssertEqual(existing.count, 1)

            guard let first = existing.first else { return ([], []) }
            XCTAssertEqual(first.id, testEntityID)
            XCTAssertEqual(first.name, testEntityName)

            let entity = TestEntity(in: testContext, id: testNewEntityID, name: testNewEntityName)
            try context.obtainPermanentIDs(for: [entity])
            testNewEntityObjectID = entity.objectID

            return ([entity], [entity.objectID])
        }
        let transform: TransformClosure<TestEntity, NSManagedObjectID> = { $0.objectID }

        do {
            let predicate = NSPredicate(format: "id in %@", [testEntityID, testNewEntityID])
            let objectIDs = try coreDataStack.findOrCreate(with: predicate,
                                                           contextType: .work,
                                                           filterExistingAndCreate: filterExistingAndCreate,
                                                           transform: transform)

            XCTAssertEqual(objectIDs.count, 2)
            XCTAssertTrue(objectIDs.contains(testEntityObjectID))
            XCTAssertTrue(objectIDs.contains(testNewEntityObjectID))

            testContext.validateTestEntity(with: testEntityObjectID) { entity in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
                XCTAssertEqual(entity.name, testEntityName)
            }

            testContext.validateTestEntity(with: testNewEntityObjectID) { entity in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testNewEntityID)
                XCTAssertEqual(entity.name, testNewEntityName)
            }

        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testFindOrCreate_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: MockError.💥)

        let filterExistingAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { _, _ in
            throw MockError.💩
        }
        let transform: TransformClosure<TestEntity, NSManagedObjectID> = { _ in throw MockError.💩 }

        do {
            let _ = try coreDataStack.findOrCreate(with: .id(1337),
                                                   contextType: .work,
                                                   filterExistingAndCreate: filterExistingAndCreate,
                                                   transform: transform)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    // MARK: create

    func testCreate_WithValidEntityAndNonThrowingCreateClosure_ShouldSucceed() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!
        let testEntityID: Int64 = 1337
        let testEntityName: String = "test"

        let create: CreateClosure<TestEntity, NSManagedObjectID> = { context in
            let entity = TestEntity(in: context, id: 1337, name: testEntityName)
            try context.obtainPermanentIDs(for: [entity])
            testEntityObjectID = entity.objectID

            return ([entity], [entity.objectID])
        }

        do {
            let objectIDs = try coreDataStack.create(contextType: .work, create: create)

            XCTAssertEqual(objectIDs.count, 1)
            XCTAssertTrue(objectIDs.contains(testEntityObjectID))

            testContext.validateTestEntity(with: testEntityObjectID) { entity in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
                XCTAssertEqual(entity.name, testEntityName)
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCreate_WithThrowingCreateClosure_ShouldThrow() {

        let create: CreateClosure<TestEntity, NSManagedObjectID> = { _ in throw MockError.💥}

        do {
            let _ = try coreDataStack.create(contextType: .work, create: create)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCreate_WithThrowingManagedObjectContext_ShouldThrow() {
        
        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: MockError.💥)

        let create: CreateClosure<TestEntity, NSManagedObjectID> = { context in
            let entity = TestEntity(in: context, id: 1337, name: nil)
            try context.obtainPermanentIDs(for: [entity])
            return ([entity], [entity.objectID])
        }

        do {
            let _ = try coreDataStack.create(contextType: .work, create: create)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    // MARK: createOrUpdate

    func testCreateOrUpdate_WithNonExistingEntity_ShouldCreateIt() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!
        let testEntityID: Int64 = 1337
        let testEntityName: String = "test"

        let filterUpdatedAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { (updated, context) in
            XCTAssertTrue(updated.isEmpty)

            let entity = TestEntity(in: context, id: testEntityID, name: testEntityName)
            try context.obtainPermanentIDs(for: [entity])
            testEntityObjectID = entity.objectID

            return ([entity], [entity.objectID])
        }
        let update: UpdateClosure<TestEntity, NSManagedObjectID> = { _ in throw MockError.💩 }

        do {
            let objectIDs = try coreDataStack.createOrUpdate(with: .id(testEntityID),
                                                             contextType: .work,
                                                             filterUpdatedAndCreate: filterUpdatedAndCreate,
                                                             update: update)

            XCTAssertEqual(objectIDs.count, 1)
            XCTAssertTrue(objectIDs.contains(testEntityObjectID))

            testContext.validateTestEntity(with: testEntityObjectID) { entity in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
                XCTAssertEqual(entity.name, testEntityName)
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCreateOrUpdate_WithNonExistingEntityAndThrowingCreateClosure_ShouldThrow() {

        let filterUpdatedAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { _, _ in
            throw MockError.💥
        }
        let update: UpdateClosure<TestEntity, NSManagedObjectID> = { _ in throw MockError.💩 }

        do {
            let _ = try coreDataStack.createOrUpdate(with: .id(1337),
                                                     contextType: .work,
                                                     filterUpdatedAndCreate: filterUpdatedAndCreate,
                                                     update: update)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCreateOrUpdate_WithExistingEntity_ShouldUpdateAndReturnIt() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!
        let testEntityID: Int64 = 1337
        let testEntityName: String = "original"
        let testUpdatedEntityName: String = "updated"

        do { testEntityObjectID = try testContext.createTestEntity(id: testEntityID, name: testEntityName) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let filterUpdatedAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { (updated, context) in
            XCTAssertEqual(updated.count, 1)

            guard let first = updated.first else { return ([], []) }
            XCTAssertEqual(first.id, testEntityID)
            XCTAssertEqual(first.name, testEntityName)

            return ([], [])
        }

        let update: UpdateClosure<TestEntity, NSManagedObjectID> = { entity in
            XCTAssertEqual(entity.id, testEntityID)
            XCTAssertEqual(entity.name, testEntityName)

            entity.name = testUpdatedEntityName
            return entity.objectID
        }

        do {
            let objectIDs = try coreDataStack.createOrUpdate(with: .id(testEntityID),
                                                             contextType: .work,
                                                             filterUpdatedAndCreate: filterUpdatedAndCreate,
                                                             update: update)

            XCTAssertEqual(objectIDs.count, 1)
            XCTAssertTrue(objectIDs.contains(testEntityObjectID))

            testContext.validateTestEntity(with: testEntityObjectID) { entity in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
                XCTAssertEqual(entity.name, testUpdatedEntityName)
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCreateOrUpdate_WithExistingEntityAndThrowingUpdateClosure_ShouldThrow() {

        let testEntityID: Int64 = 1337
        do { let _ = try coreDataStack.context(withType: .work).createTestEntity(id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let filterUpdatedAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { (updated, context) in
            XCTAssertEqual(updated.count, 1)

            guard let first = updated.first else { return ([], []) }
            XCTAssertEqual(first.id, testEntityID)

            return ([], [])
        }

        let update: UpdateClosure<TestEntity, NSManagedObjectID> = { _ in throw MockError.💥 }

        do {
            let _ = try coreDataStack.createOrUpdate(with: .id(testEntityID),
                                                     contextType: .work,
                                                     filterUpdatedAndCreate: filterUpdatedAndCreate,
                                                     update: update)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCreateOrUpdate_WithExistingAndNonExistingEntities_ShouldUpdateOneAndCreateAnother() {

        let testContext = coreDataStack.context(withType: .work)

        var testEntityObjectID: NSManagedObjectID!
        let testEntityID: Int64 = 1337
        let testEntityName: String = "original"
        let testUpdatedEntityName: String = "updated"

        var testNewEntityObjectID: NSManagedObjectID!
        let testNewEntityID: Int64 = 7331
        let testNewEntityName: String = "new"

        do { testEntityObjectID = try testContext.createTestEntity(id: testEntityID, name: testEntityName) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let filterUpdatedAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { (updated, context) in
            XCTAssertEqual(updated.count, 1)

            guard let first = updated.first else { return ([], []) }
            XCTAssertEqual(first.id, testEntityID)
            XCTAssertEqual(first.name, testEntityName)

            let entity = TestEntity(in: testContext, id: testNewEntityID, name: testNewEntityName)
            try context.obtainPermanentIDs(for: [entity])
            testNewEntityObjectID = entity.objectID

            return ([entity], [entity.objectID])
        }

        let update: UpdateClosure<TestEntity, NSManagedObjectID> = { entity in
            XCTAssertEqual(entity.id, testEntityID)
            XCTAssertEqual(entity.name, testEntityName)

            entity.name = testUpdatedEntityName
            return entity.objectID
        }

        do {
            let predicate = NSPredicate(format: "id in %@", [testEntityID, testNewEntityID])
            let objectIDs = try coreDataStack.createOrUpdate(with: predicate,
                                                             contextType: .work,
                                                             filterUpdatedAndCreate: filterUpdatedAndCreate,
                                                             update: update)

            XCTAssertEqual(objectIDs.count, 2)
            XCTAssertTrue(objectIDs.contains(testEntityObjectID))
            XCTAssertTrue(objectIDs.contains(testNewEntityObjectID))

            testContext.validateTestEntity(with: testEntityObjectID) { entity in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
                XCTAssertEqual(entity.name, testUpdatedEntityName)
            }

            testContext.validateTestEntity(with: testNewEntityObjectID) { entity in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testNewEntityID)
                XCTAssertEqual(entity.name, testNewEntityName)
            }
            
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCreateOrUpdate_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: MockError.💥)

        let filterUpdatedAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { _, _ in
            throw MockError.💩
        }
        let update: UpdateClosure<TestEntity, NSManagedObjectID> = { _ in throw MockError.💩 }

        do {
            let _ = try coreDataStack.createOrUpdate(with: .id(1337),
                                                     contextType: .work,
                                                     filterUpdatedAndCreate: filterUpdatedAndCreate,
                                                     update: update)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    // MARK: update

    func testUpdate_WithExistingEntitiesAndNonThrowingUpdateClosure_ShouldUpdateMatches() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!
        let testEntityID: Int64 = 1337
        let testUpdatedEntityName: String = "test"
        do { testEntityObjectID = try testContext.createTestEntity(id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let update: UpdateClosure<TestEntity, NSManagedObjectID> = {
            $0.name = testUpdatedEntityName
            return $0.objectID
        }

        do {
            let objectIDs = try coreDataStack.update(with: .id(testEntityID), contextType: .work, update: update)

            XCTAssertEqual(objectIDs.count, 1)
            XCTAssertTrue(objectIDs.contains(testEntityObjectID))

            testContext.validateTestEntity(with: testEntityObjectID) { entity in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
                XCTAssertEqual(entity.name, testUpdatedEntityName)
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testUpdate_WithNonExistingEntities_ShouldReturnNoMatches() {

        let update: UpdateClosure<TestEntity, NSManagedObjectID> = { _ in throw MockError.💩 }

        do {
            let resultNames = try coreDataStack.update(with: .id(1337), contextType: .work, update: update)

            XCTAssert(resultNames.isEmpty)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testUpdate_WithExistingEntitiesAndThrowingUpdateClosure_ShouldThrow() {

        let testEntityID: Int64 = 1337
        do { let _ = try coreDataStack.context(withType: .work).createTestEntity(id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let update: UpdateClosure<TestEntity, NSManagedObjectID> = { _ in throw MockError.💥 }

        do {
            let _ = try coreDataStack.update(with: .id(1337), contextType: .work, update: update)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testUpdate_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: MockError.💥)

        let update: UpdateClosure<TestEntity, NSManagedObjectID> = { _ in throw MockError.💩 }

        do {
            let _ = try coreDataStack.update(with: .id(1337), contextType: .work, update: update)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    // MARK: delete

    func testDelete_WithExistingEntitiesAndNoCleanupClosure_ShouldDeleteThem() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!
        let testEntityID: Int64 = 1337
        do { testEntityObjectID = try testContext.createTestEntity(id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        do {
            let deleted = try coreDataStack.delete(TestEntity.self,
                                                   predicate: .id(testEntityID),
                                                   contextType: .work)

            XCTAssertEqual(deleted, 1)

            testContext.validateTestEntity(with: testEntityObjectID) { entity in
                if let _ = entity { XCTFail("🔥: unexpected existent entity!") }
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testDelete_WithSQLiteStoreAndExistingEntitiesAndNoCleanupClosure_ShouldDeleteThem() {

        // Test the codepath where `delete` uses a `NSBatchDeleteRequest` (only available on SQLite stores)
        let libraryDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let testStoreURL = libraryDirectory.appendingPathComponent("testBatchDeleteStore.sqlite")

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
        let testEntityID: Int64 = 1337
        do { testEntityObjectID = try testContext.createTestEntity(id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        do {
            let deleted = try sqLiteCoreDataStack.delete(TestEntity.self,
                                                         predicate: .id(testEntityID),
                                                         contextType: .work)

            XCTAssertEqual(deleted, 1)
            
            testContext.validateTestEntity(with: testEntityObjectID) { entity in
                if let existent = entity, existent.isDeleted == false { XCTFail("🔥: unexpected existent entity!") }
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testDelete_WithExistingEntitiesAndCleanupClosure_ShouldCallCleanupAndThenDeleteThem() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!
        let testEntityID: Int64 = 1337
        do { testEntityObjectID = try testContext.createTestEntity(id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let cleanup: (TestEntity) -> Void = { entity in
            XCTAssertEqual(entity.id, testEntityID)
        }

        do {
            let deleted = try coreDataStack.delete(TestEntity.self,
                                                   predicate: .id(testEntityID),
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

    func testDelete_WithNonExistingEntity_ShouldDoNothing() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!
        let testEntityID: Int64 = 1337
        let nonExistingEntityID: Int64 = 0
        do { testEntityObjectID = try testContext.createTestEntity(id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        do {
            let deleted = try coreDataStack.delete(TestEntity.self,
                                                   predicate: .id(nonExistingEntityID),
                                                   contextType: .work)

            XCTAssertEqual(deleted, 0)

            testContext.validateTestEntity(with: testEntityObjectID) { entity in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testDelete_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: MockError.💥)

        do {
            let _ = try coreDataStack.delete(TestEntity.self, predicate: .id(1337), contextType: .work)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    // MARK: count

    func testCount_WithMatchingEntities_ShouldReturnCount() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!
        let testEntityID: Int64 = 1337
        do { testEntityObjectID = try testContext.createTestEntity(id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        do {
            let count = try coreDataStack.count(TestEntity.self, with: .id(testEntityID), contextType: .work)

            XCTAssertEqual(count, 1)

            testContext.validateTestEntity(with: testEntityObjectID) { entity in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCount_WithNonMatchingEntities_ShouldReturnZero() {

        do {
            let count = try coreDataStack.count(TestEntity.self, with: .id(1337), contextType: .work)

            XCTAssertEqual(count, 0)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCount_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: MockError.💥)

        do {
            let _ = try coreDataStack.count(TestEntity.self, with: .id(1337), contextType: .work)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    // MARK: performClosure

    func testPerformClosure_WithMatchingEntities_ShouldInvokeClosureWithMatches() {

        let testEntityID: Int64 = 1337
        do { let _ = try coreDataStack.context(withType: .work).createTestEntity(id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let closure: ([TestEntity]) -> Void = { entities in
            XCTAssertEqual(entities.count, 1)
            guard let first = entities.first else { return }
            XCTAssertEqual(first.id, testEntityID)
        }

        do {
            try coreDataStack.performClosure(TestEntity.self,
                                             with: .id(testEntityID),
                                             contextType: .work,
                                             closure: closure)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testPerformClosure_WithNoMatchingEntities_ShouldInvokeClosureWithEmptyArray() {

        do {
            try coreDataStack.performClosure(TestEntity.self, with: .id(1337), contextType: .work) { entities in
                XCTAssertTrue(entities.isEmpty)
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testPerformClosure_WithMatchingEntitiesAndPersistChanges_ShouldInvokeClosureWithMatchesAndPersistChanges() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!
        let testEntityID: Int64 = 1337
        let testUpdatedEntityName: String = "test"
        do { testEntityObjectID = try testContext.createTestEntity(id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let closure: ([TestEntity]) -> Void = { entities in
            XCTAssertEqual(entities.count, 1)
            guard let first = entities.first else { return }

            first.name = testUpdatedEntityName
        }

        do {
            try coreDataStack.performClosure(TestEntity.self,
                                             with: .id(testEntityID),
                                             objectsAsFaults: false,
                                             contextType: .work,
                                             persistChanges: true,
                                             closure: closure)

            testContext.validateTestEntity(with: testEntityObjectID) { entity in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
                XCTAssertEqual(entity.name, testUpdatedEntityName)
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testPerformClosure_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: MockError.💥)

        do {
            try coreDataStack.performClosure(TestEntity.self, with: .id(1337), contextType: .work) { _ in
                XCTFail("🔥: Test failed with unexpectedly called closure!")
            }

            XCTFail("🔥: Test failed with unexpected success!")
        } catch MockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }
}


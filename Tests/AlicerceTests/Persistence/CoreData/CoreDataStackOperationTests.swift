//
//  CoreDataStackOperationTests.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 16/03/2017.
//  Copyright © 2017 net-a-porter. All rights reserved.
//

import XCTest
import CoreData
@testable import Alicerce

extension TestEntity: CoreDataEntity {

    convenience init(in context: NSManagedObjectContext, id: Int64, name: String?) {
        self.init(context: context)
        self.id = id
        self.name = name
    }
}

extension MockErrorManagedObjectContext {

    convenience init(mockError: Error) {
        self.init(concurrencyType: .privateQueueConcurrencyType)
        self.mockError = mockError
    }
}

class CoreDataStackOperationTests: XCTestCase {

    enum CoreDataStackMockError: Error { case 💥, 💩 }

    typealias TransformClosure<Internal, External> = (Internal) throws -> External
    typealias CreateClosure<Internal, External> = (NSManagedObjectContext) throws -> ([Internal], [External])
    typealias UpdateClosure<Internal, External> = (Internal) throws -> External
    typealias FilterAndCreateClosure<Internal, External> = ([Internal], NSManagedObjectContext) throws -> ([Internal], [External])

    fileprivate var coreDataStack: MockCoreDataStack!

    fileprivate var testBundle: Bundle {
        return Bundle(for: type(of: self))
    }

    fileprivate lazy var managedObjectModel: NSManagedObjectModel = {
        return try! MockCoreDataStack.managedObjectModel(withModelName: "CoreDataStackModel", in: self.testBundle)
    }()

    override func setUp() {
        super.setUp()

        coreDataStack = MockCoreDataStack(storeType: .inMemory,
                                          storeName: "test",
                                          managedObjectModel: managedObjectModel)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()

        coreDataStack = nil
    }


    // MARK: fetchedResultsController

    func testFetchedResultsController_WithGivenContextType_ShouldHaveCorrectContext() {

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

        XCTAssertEqual(backgroundFetchedResultsController.managedObjectContext, coreDataStack.context(withType: .background))
    }

    func testFetchedResultsController_WithGivenFetchRequestAndSectionAndCache_ShouldHaveCorrectValues() {

        let testSectionNameKeyPath = "name"
        let testFetchRequest: NSFetchRequest<TestEntity> = TestEntity.fetchRequest()
        testFetchRequest.sortDescriptors = [NSSortDescriptor(key: testSectionNameKeyPath, ascending: true)]
        let testCacheName = "testCache"

        let fetchedResultsController = coreDataStack.fetchedResultsController(fetchRequest: testFetchRequest,
                                                                              sectionNameKeyPath: testSectionNameKeyPath,
                                                                              cacheName: testCacheName,
                                                                              contextType: .work)

        XCTAssertEqual(fetchedResultsController.fetchRequest, testFetchRequest)
        XCTAssertEqual(fetchedResultsController.sectionNameKeyPath, testSectionNameKeyPath)
        XCTAssertEqual(fetchedResultsController.cacheName, testCacheName)
    }

    // MARK: - CRUD

    // MARK: exists

    func testExists_WithExistingEntity_ShouldReturnTrue() {

        let testContext = coreDataStack.context(withType: .work)
        var testEntityObjectID: NSManagedObjectID!
        let testEntityID: Int64 = 1337
        do { testEntityObjectID = try createTestEntity(in: testContext, id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        // test
        do {
            let testExists = try coreDataStack.exists(TestEntity.self,
                                                      predicate: NSPredicate(format: "id = %d", testEntityID),
                                                      contextType: .work)

            XCTAssertTrue(testExists)

            validateTestEntity(with: testEntityObjectID, in: testContext) { (entity: TestEntity?) in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testExists_WithNonExistingEntity_ShouldReturnFalse() {

        do {
            let testExists = try coreDataStack.exists(TestEntity.self,
                                                      predicate: NSPredicate(format: "id = %d", 1337),
                                                      contextType: .work)

            XCTAssertFalse(testExists)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testExists_WithThrowingManagedObjectContext_ShouldThrowError() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: CoreDataStackMockError.💥)

        do {
            let _ = try coreDataStack.exists(TestEntity.self,
                                             predicate: NSPredicate(format: "name = %@", "💥"),
                                             contextType: .work)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch CoreDataStackMockError.💥 {
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
        do { testEntityObjectID = try createTestEntity(in: testContext, id: testEntityID, name: testEntityName) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let transform: TransformClosure<TestEntity, NSManagedObjectID> = { return $0.objectID }

        do {
            let objectIDs = try coreDataStack.fetch(with: NSPredicate(format: "id = %d", 1337), transform: transform)

            XCTAssertEqual(objectIDs.count, 1)
            XCTAssertTrue(objectIDs.contains(testEntityObjectID))
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testFetch_WithNonMatchingPredicate_ShouldReturnNoMatches() {

        let testEntityID: Int64 = 1337
        do { let _ = try createTestEntity(in: coreDataStack.context(withType: .work), id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let transform: TransformClosure<TestEntity, NSManagedObjectID> = { _ in throw CoreDataStackMockError.💩 }

        do {
            let matches = try coreDataStack.fetch(with: NSPredicate(format: "id = %d", 0), transform: transform)

            XCTAssert(matches.isEmpty)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testFetch_WithMatchingPredicateAndThrowingTransformClosure_ShouldThrow() {

        let testEntityID: Int64 = 1337
        do { let _ = try createTestEntity(in: coreDataStack.context(withType: .work), id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let transform: TransformClosure<TestEntity, NSManagedObjectID> = { _ in throw CoreDataStackMockError.💥 }

        do {
            let _ = try coreDataStack.fetch(with: NSPredicate(format: "id = %d", testEntityID), transform: transform)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch CoreDataStackMockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testFetch_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: CoreDataStackMockError.💥)

        let transform: TransformClosure<TestEntity, NSManagedObjectID> = { _ in throw CoreDataStackMockError.💩 }

        do {
            let _ = try coreDataStack.fetch(with: NSPredicate(format: "id = %d", 1337), transform: transform)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch CoreDataStackMockError.💥 {
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

        let filterExistingAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { (existing, context) in
            XCTAssertTrue(existing.isEmpty)

            let entity = TestEntity(in: testContext, id: testEntityID, name: testEntityName)
            try context.obtainPermanentIDs(for: [entity])
            testEntityObjectID = entity.objectID

            return ([entity], [entity.objectID])
        }

        let transform: TransformClosure<TestEntity, NSManagedObjectID> = { _ in throw CoreDataStackMockError.💩 }

        do {
            let objectIDs = try coreDataStack.findOrCreate(with: NSPredicate(format: "id = %d", testEntityID),
                                                           filterExistingAndCreate: filterExistingAndCreate,
                                                           transform: transform)

            XCTAssertEqual(objectIDs.count, 1)
            XCTAssertTrue(objectIDs.contains(testEntityObjectID))

            validateTestEntity(with: testEntityObjectID, in: testContext) { (entity: TestEntity?) in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
                XCTAssertEqual(entity.name, testEntityName)
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testFindOrCreate_WithNonExistingEntityAndThrowingFilterAndCreateClosure_ShouldThrow() {

        let filterExistingAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { _, _  in throw CoreDataStackMockError.💥 }
        let transform: TransformClosure<TestEntity, NSManagedObjectID> = { _ in throw CoreDataStackMockError.💩 }

        do {
            let _ = try coreDataStack.findOrCreate(with: NSPredicate(format: "id = %d", 1337),
                                                   filterExistingAndCreate: filterExistingAndCreate,
                                                   transform: transform)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch CoreDataStackMockError.💥 {
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

        do { testEntityObjectID = try createTestEntity(in: testContext, id: testEntityID, name: testEntityName) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let filterExistingAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { (existing, context) in
            XCTAssertEqual(existing.count, 1)

            guard let first = existing.first else { return ([], []) }
            XCTAssertEqual(first.id, testEntityID)
            XCTAssertEqual(first.name, testEntityName)

            return ([], [])
        }
        let transform: TransformClosure<TestEntity, NSManagedObjectID> = { $0.objectID }

        do {
            let objectIDs = try coreDataStack.findOrCreate(with: NSPredicate(format: "id = %d", testEntityID),
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
        do { let _ = try createTestEntity(in: coreDataStack.context(withType: .work), id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let filterExistingAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { (existing, context) in
            XCTAssertEqual(existing.count, 1)

            guard let first = existing.first else { return ([], []) }
            XCTAssertEqual(first.id, testEntityID)

            return ([], [])
        }
        let transform: TransformClosure<TestEntity, NSManagedObjectID> = { _ in throw CoreDataStackMockError.💥 }

        do {
            let _ = try coreDataStack.findOrCreate(with: NSPredicate(format: "id = %d", testEntityID),
                                                   filterExistingAndCreate: filterExistingAndCreate,
                                                   transform: transform)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch CoreDataStackMockError.💥 {
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

        do { testEntityObjectID = try createTestEntity(in: testContext, id: testEntityID, name: testEntityName) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let filterExistingAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { (existing, context) in
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
                                                           filterExistingAndCreate: filterExistingAndCreate,
                                                           transform: transform)

            XCTAssertEqual(objectIDs.count, 2)
            XCTAssertTrue(objectIDs.contains(testEntityObjectID))
            XCTAssertTrue(objectIDs.contains(testNewEntityObjectID))

            validateTestEntity(with: testEntityObjectID, in: testContext) { (entity: TestEntity?) in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
                XCTAssertEqual(entity.name, testEntityName)
            }

            validateTestEntity(with: testNewEntityObjectID, in: testContext) { (entity: TestEntity?) in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testNewEntityID)
                XCTAssertEqual(entity.name, testNewEntityName)
            }

        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testFindOrCreate_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: CoreDataStackMockError.💥)

        let filterExistingAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { _, _ in throw CoreDataStackMockError.💩 }
        let transform: TransformClosure<TestEntity, NSManagedObjectID> = { _ in throw CoreDataStackMockError.💩 }

        do {
            let _ = try coreDataStack.findOrCreate(with: NSPredicate(format: "id = %d", 1337),
                                                   filterExistingAndCreate: filterExistingAndCreate,
                                                   transform: transform)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch CoreDataStackMockError.💥 {
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
            let objectIDs = try coreDataStack.create(create: create)

            XCTAssertEqual(objectIDs.count, 1)
            XCTAssertTrue(objectIDs.contains(testEntityObjectID))

            validateTestEntity(with: testEntityObjectID, in: testContext) { (entity: TestEntity?) in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
                XCTAssertEqual(entity.name, testEntityName)
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCreate_WithThrowingCreateClosure_ShouldThrow() {

        let create: CreateClosure<TestEntity, NSManagedObjectID> = { _ in throw CoreDataStackMockError.💥}

        do {
            let _ = try coreDataStack.create(create: create)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch CoreDataStackMockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCreate_WithThrowingManagedObjectContext_ShouldThrow() {
        
        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: CoreDataStackMockError.💥)

        let create: CreateClosure<TestEntity, NSManagedObjectID> = { context in
            let entity = TestEntity(in: context, id: 1337, name: nil)
            try context.obtainPermanentIDs(for: [entity])
            return ([entity], [entity.objectID])
        }

        do {
            let _ = try coreDataStack.create(create: create)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch CoreDataStackMockError.💥 {
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
        let update: UpdateClosure<TestEntity, NSManagedObjectID> = { _ in throw CoreDataStackMockError.💩 }

        do {
            let objectIDs = try coreDataStack.createOrUpdate(with: NSPredicate(format: "id = %d", testEntityID),
                                                             filterUpdatedAndCreate: filterUpdatedAndCreate,
                                                             update: update)

            XCTAssertEqual(objectIDs.count, 1)
            XCTAssertTrue(objectIDs.contains(testEntityObjectID))

            validateTestEntity(with: testEntityObjectID, in: testContext) { (entity: TestEntity?) in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
                XCTAssertEqual(entity.name, testEntityName)
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCreateOrUpdate_WithNonExistingEntityAndThrowingCreateClosure_ShouldThrow() {

        let filterUpdatedAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { _, _ in throw CoreDataStackMockError.💥 }
        let update: UpdateClosure<TestEntity, NSManagedObjectID> = { _ in throw CoreDataStackMockError.💩 }

        do {
            let _ = try coreDataStack.createOrUpdate(with: NSPredicate(format: "id = %d", 1337),
                                                     filterUpdatedAndCreate: filterUpdatedAndCreate,
                                                     update: update)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch CoreDataStackMockError.💥 {
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

        do { testEntityObjectID = try createTestEntity(in: testContext, id: testEntityID, name: testEntityName) }
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
            let objectIDs = try coreDataStack.createOrUpdate(with: NSPredicate(format: "id = %d", testEntityID),
                                                            filterUpdatedAndCreate: filterUpdatedAndCreate,
                                                            update: update)

            XCTAssertEqual(objectIDs.count, 1)
            XCTAssertTrue(objectIDs.contains(testEntityObjectID))

            validateTestEntity(with: testEntityObjectID, in: testContext) { (entity: TestEntity?) in
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
        do { let _ = try createTestEntity(in: coreDataStack.context(withType: .work), id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let filterUpdatedAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { (updated, context) in
            XCTAssertEqual(updated.count, 1)

            guard let first = updated.first else { return ([], []) }
            XCTAssertEqual(first.id, testEntityID)

            return ([], [])
        }

        let update: UpdateClosure<TestEntity, NSManagedObjectID> = { _ in throw CoreDataStackMockError.💥 }

        do {
            let _ = try coreDataStack.createOrUpdate(with: NSPredicate(format: "id = %d", testEntityID),
                                                     filterUpdatedAndCreate: filterUpdatedAndCreate,
                                                     update: update)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch CoreDataStackMockError.💥 {
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

        do { testEntityObjectID = try createTestEntity(in: testContext, id: testEntityID, name: testEntityName) }
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
                                                             filterUpdatedAndCreate: filterUpdatedAndCreate,
                                                             update: update)

            XCTAssertEqual(objectIDs.count, 2)
            XCTAssertTrue(objectIDs.contains(testEntityObjectID))
            XCTAssertTrue(objectIDs.contains(testNewEntityObjectID))

            validateTestEntity(with: testEntityObjectID, in: testContext) { (entity: TestEntity?) in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
                XCTAssertEqual(entity.name, testUpdatedEntityName)
            }

            validateTestEntity(with: testNewEntityObjectID, in: testContext) { (entity: TestEntity?) in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testNewEntityID)
                XCTAssertEqual(entity.name, testNewEntityName)
            }
            
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCreateOrUpdate_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: CoreDataStackMockError.💥)

        let filterUpdatedAndCreate: FilterAndCreateClosure<TestEntity, NSManagedObjectID> = { _, _ in throw CoreDataStackMockError.💩 }
        let update: UpdateClosure<TestEntity, NSManagedObjectID> = { _ in throw CoreDataStackMockError.💩 }

        do {
            let _ = try coreDataStack.createOrUpdate(with: NSPredicate(format: "id = %d", 1337),
                                                     filterUpdatedAndCreate: filterUpdatedAndCreate,
                                                     update: update)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch CoreDataStackMockError.💥 {
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
        do { testEntityObjectID = try createTestEntity(in: testContext, id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let update: UpdateClosure<TestEntity, NSManagedObjectID> = {
            $0.name = testUpdatedEntityName
            return $0.objectID
        }

        do {
            let objectIDs = try coreDataStack.update(with: NSPredicate(format: "id = %d", testEntityID),
                                                     update: update)

            XCTAssertEqual(objectIDs.count, 1)
            XCTAssertTrue(objectIDs.contains(testEntityObjectID))

            validateTestEntity(with: testEntityObjectID, in: testContext) { (entity: TestEntity?) in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
                XCTAssertEqual(entity.name, testUpdatedEntityName)
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testUpdate_WithNonExistingEntities_ShouldReturnNoMatches() {

        let update: UpdateClosure<TestEntity, NSManagedObjectID> = { _ in throw CoreDataStackMockError.💩 }

        do {
            let resultNames = try coreDataStack.update(with: NSPredicate(format: "id = %d", 1337), update: update)

            XCTAssert(resultNames.isEmpty)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testUpdate_WithExistingEntitiesAndThrowingUpdateClosure_ShouldThrow() {

        let testEntityID: Int64 = 1337
        do { let _ = try createTestEntity(in: coreDataStack.context(withType: .work), id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let update: UpdateClosure<TestEntity, NSManagedObjectID> = { _ in throw CoreDataStackMockError.💥 }

        do {
            let _ = try coreDataStack.update(with: NSPredicate(format: "id = %d", 1337), update: update)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch CoreDataStackMockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testUpdate_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: CoreDataStackMockError.💥)

        let update: UpdateClosure<TestEntity, NSManagedObjectID> = { _ in throw CoreDataStackMockError.💩 }

        do {
            let _ = try coreDataStack.update(with: NSPredicate(format: "id = %d", 1337), update: update)

            XCTFail("🔥: Test failed with unexpected success!")
        } catch CoreDataStackMockError.💥 {
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
        do { testEntityObjectID = try createTestEntity(in: testContext, id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        do {
            let deleted = try coreDataStack.delete(TestEntity.self,
                                                   predicate: NSPredicate(format: "id = %d", testEntityID))

            XCTAssertEqual(deleted, 1)

            validateTestEntity(with: testEntityObjectID, in: testContext) { (entity: TestEntity?) in
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
        do { testEntityObjectID = try createTestEntity(in: testContext, id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        do {
            let deleted = try sqLiteCoreDataStack.delete(TestEntity.self,
                                                         predicate: NSPredicate(format: "id = %d", testEntityID))

            XCTAssertEqual(deleted, 1)
            
            validateTestEntity(with: testEntityObjectID, in: testContext) { (entity: TestEntity?) in
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
        do { testEntityObjectID = try createTestEntity(in: testContext, id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let cleanup: (TestEntity) -> Void = { entity in
            XCTAssertEqual(entity.id, testEntityID)
        }

        do {
            let deleted = try coreDataStack.delete(TestEntity.self,
                                                   predicate: NSPredicate(format: "id = %d", testEntityID),
                                                   cleanup: cleanup)

            XCTAssertEqual(deleted, 1)

            validateTestEntity(with: testEntityObjectID, in: testContext) { (entity: TestEntity?) in
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
        do { testEntityObjectID = try createTestEntity(in: testContext, id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        do {
            let deleted = try coreDataStack.delete(TestEntity.self,
                                                   predicate: NSPredicate(format: "id = %d", nonExistingEntityID))

            XCTAssertEqual(deleted, 0)

            validateTestEntity(with: testEntityObjectID, in: testContext) { (entity: TestEntity?) in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testDelete_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: CoreDataStackMockError.💥)

        do {
            let _ = try coreDataStack.delete(TestEntity.self, predicate: NSPredicate(format: "id = %d", 1337))

            XCTFail("🔥: Test failed with unexpected success!")
        } catch CoreDataStackMockError.💥 {
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
        do { testEntityObjectID = try createTestEntity(in: testContext, id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        do {
            let count = try coreDataStack.count(TestEntity.self,
                                                predicate: NSPredicate(format: "id = %d", testEntityID))

            XCTAssertEqual(count, 1)

            validateTestEntity(with: testEntityObjectID, in: testContext) { (entity: TestEntity?) in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCount_WithNonMatchingEntities_ShouldReturnZero() {

        do {
            let count = try coreDataStack.count(TestEntity.self,
                                                predicate: NSPredicate(format: "id = %d", 1337))

            XCTAssertEqual(count, 0)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testCount_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: CoreDataStackMockError.💥)

        do {
            let _ = try coreDataStack.count(TestEntity.self, predicate: NSPredicate(format: "id = %d", 1337))

            XCTFail("🔥: Test failed with unexpected success!")
        } catch CoreDataStackMockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    // MARK: performClosure

    func testPerformClosure_WithMatchingEntities_ShouldInvokeClosureWithMatches() {

        let testEntityID: Int64 = 1337
        do { let _ = try createTestEntity(in: coreDataStack.context(withType: .work), id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let closure: ([TestEntity]) -> Void = { entities in
            XCTAssertEqual(entities.count, 1)
            guard let first = entities.first else { return }
            XCTAssertEqual(first.id, testEntityID)
        }

        do {
            try coreDataStack.performClosure(with: NSPredicate(format: "id = %d", testEntityID), closure)
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testPerformClosure_WithNoMatchingEntities_ShouldInvokeClosureWithEmptyArray() {

        do {
            try coreDataStack.performClosure(with: NSPredicate(format: "id = %d", 1337)) { (entities: [TestEntity]) in
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
        do { testEntityObjectID = try createTestEntity(in: testContext, id: testEntityID, name: nil) }
        catch { return XCTFail("🔥: failed to create test entity: \(error)") }

        let closure: ([TestEntity]) -> Void = { entities in
            XCTAssertEqual(entities.count, 1)
            guard let first = entities.first else { return }

            first.name = testUpdatedEntityName
        }

        do {
            try coreDataStack.performClosure(with: NSPredicate(format: "id = %d", testEntityID),
                                             objectsAsFaults: false,
                                             persistChanges: true,
                                             closure)

            validateTestEntity(with: testEntityObjectID, in: testContext) { (entity: TestEntity?) in
                guard let entity = entity, entity.isDeleted == false else { return XCTFail("🔥: non existent entity!") }
                XCTAssertEqual(entity.id, testEntityID)
                XCTAssertEqual(entity.name, testUpdatedEntityName)
            }
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    func testPerformClosure_WithThrowingManagedObjectContext_ShouldThrow() {

        coreDataStack.mockWorkContext = MockErrorManagedObjectContext(mockError: CoreDataStackMockError.💥)

        do {
            try coreDataStack.performClosure(with: NSPredicate(format: "id = %d", 1337)) { (_: [TestEntity]) in
                XCTFail("🔥: Test failed with unexpectedly called closure!")
            }

            XCTFail("🔥: Test failed with unexpected success!")
        } catch CoreDataStackMockError.💥 {
            // expected error 💪
        } catch {
            XCTFail("🔥: Test failed with error: \(error)")
        }
    }

    // MARK: - Auxiliary

    func createTestEntity(in context: NSManagedObjectContext, id: Int64, name: String?) throws -> NSManagedObjectID {

        var objectID: NSManagedObjectID!
        var error: Error?

        context.performAndWait {
            let entity = TestEntity(in: context, id: id, name: name)

            do {
                try context.save()

                if let parent = context.parent {
                    parent.performAndWait {
                        do { try parent.save() }
                        catch let saveError { error = saveError }
                    }
                    if let error = error { throw error }
                }

                try context.obtainPermanentIDs(for: [entity])

                objectID = entity.objectID
            }
            catch let saveError { error = saveError }
        }

        if let error = error { throw error }

        return objectID
    }

    func validateTestEntity(with objectID: NSManagedObjectID,
                            in context: NSManagedObjectContext,
                            _ validate: @escaping (TestEntity?) -> Void) {

        var error: Error?

        context.performAndWait {
            do {
                guard let object = try context.existingObject(with: objectID) as? TestEntity else {
                    fatalError("🔥: Unexpected `NSManagedObject` subclass!")
                }

                validate(object)
            }
            catch let nsError as NSError
            where nsError.domain == NSCocoaErrorDomain && nsError.code == NSManagedObjectReferentialIntegrityError {
                // expected error when the object doesn't exist
                validate(nil)
            }
            catch let coreDataError {
                error = coreDataError
            }
        }

        if let error = error { XCTFail("🔥: Test failed with error: \(error)") }
    }
}

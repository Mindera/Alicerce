import XCTest
import CoreData
import Alicerce

extension TestEntity: CoreDataEntity {

    convenience init(in context: NSManagedObjectContext, id: Int64, name: String?) {
        self.init(context: context)
        self.id = id
        self.name = name
    }
}

extension NSManagedObjectContext {

    func createTestEntity(id: Int64, name: String?) throws -> NSManagedObjectID {

        var objectID: NSManagedObjectID!
        var error: Error?

        performAndWait {
            let entity = TestEntity(in: self, id: id, name: name)

            do {
                try save()

                if let parent = parent {
                    parent.performAndWait {
                        do { try parent.save() }
                        catch let saveError { error = saveError }
                    }
                    if let error = error { throw error }
                }

                try obtainPermanentIDs(for: [entity])

                objectID = entity.objectID
            }
            catch let saveError { error = saveError }
        }

        if let error = error { throw error }

        return objectID
    }

    func validateTestEntity(with objectID: NSManagedObjectID, validate: (TestEntity?) -> Void) {

        var error: Error?

        performAndWait {
            do {
                guard let object = try existingObject(with: objectID) as? TestEntity else {
                    fatalError("🔥: Unexpected `NSManagedObject` subclass!")
                }

                validate(object)
            } catch let nsError as NSError
              where nsError.domain == NSCocoaErrorDomain && nsError.code == NSManagedObjectReferentialIntegrityError {
                // expected error when the object doesn't exist
                validate(nil)
            } catch let coreDataError {
                error = coreDataError
            }
        }

        if let error = error {
            XCTFail("🔥: TestEntity validation failed with error: \(error)")
        }
    }
}

extension NSManagedObjectContext {

    func createTestEntity(value: TestEntityValue) throws -> NSManagedObjectID {

        return try createTestEntity(id: value.id, name: value.name)
    }

    func validateTestEntity(with objectID: NSManagedObjectID, equals value: TestEntityValue) {

        performAndWait {
            do {
                guard let object = try existingObject(with: objectID) as? TestEntity else {
                    fatalError("🔥: Unexpected `NSManagedObject` subclass!")
                }

                guard object.isDeleted == false else { return XCTFail("🔥: TestEntity is marked as deleted!") }

                XCTAssertEqual(object.id, value.id)
                XCTAssertEqual(object.name, value.name)
            } catch {
                XCTFail("🔥: TestEntity validation failed with error: \(error)")
            }
        }
    }
}

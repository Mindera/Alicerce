import CoreData
@testable import Alicerce

struct TestEntityValue {

    var didInvokeReflect: ((TestEntity) -> Void)? = nil
    static var didInvokeInit: ((TestEntity) -> Void)?
    static var didInvokeFilter: (([TestEntity], [TestEntityValue]) -> Void)?

    var id: Int64
    var name: String?

    init(id: Int64, name: String?) {

        self.id = id
        self.name = name
    }
}

extension TestEntityValue: Equatable {

    static func ==(lhs: TestEntityValue, rhs: TestEntityValue) -> Bool {

        return lhs.id == rhs.id && lhs.name == rhs.name
    }
}

extension TestEntityValue: ManagedObjectReflectable {

    typealias ManagedObject = TestEntity

    func reflect(to managedObject: TestEntity) {

        didInvokeReflect?(managedObject)

        managedObject.id = id
        managedObject.name = name
    }

    init(managedObject: TestEntity) {

        TestEntityValue.didInvokeInit?(managedObject)

        self.id = managedObject.id
        self.name = managedObject.name
    }

    static func filter(_ managedObjects: [TestEntity], from reflections: [TestEntityValue]) -> [TestEntityValue] {

        didInvokeFilter?(managedObjects, reflections)

        let persistedIDs = Set(managedObjects.map { $0.id })
        return reflections.filter { persistedIDs.contains($0.id) == false }
    }
}

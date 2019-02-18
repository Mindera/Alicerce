import CoreData

public protocol ManagedObjectReflectable {
    associatedtype ManagedObject: NSManagedObject

    func reflect(to managedObject: ManagedObject)

    init(managedObject: ManagedObject)

    static func filter(_ managedObjects: [ManagedObject], from reflections: [Self]) -> [Self]
}

import CoreData

public protocol ManagedObjectReflectable {
    associatedtype ManagedObject: NSManagedObject

    func reflect(to managedObject: ManagedObject)

    init(managedObject: ManagedObject)

    static func exclude(_ lhs: [ManagedObject], from rhs: [Self]) -> [Self]
}

import CoreData

public protocol CoreDataEntity: NSFetchRequestResult {
    static var entityName: String { get }
}

public extension CoreDataEntity where Self: NSManagedObject {

    static var entityName: String {
        return "\(Self.self)"
    }

    static func fetchRequest<ResultType : NSFetchRequestResult>() -> NSFetchRequest<ResultType> {
        return NSFetchRequest(entityName: entityName)
    }

    static func batchUpdateRequest() -> NSBatchUpdateRequest {
        return NSBatchUpdateRequest(entity: entity())
    }
}

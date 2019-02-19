import Foundation

extension NSPredicate {

    static func id(_ id: Int64) -> NSPredicate { return NSPredicate(format: "id = %d", id) }

    static func name(_ name: String) -> NSPredicate { return NSPredicate(format: "name = %@", name) }
}

import CoreData

// MARK: - performThrowing

public extension NSManagedObjectContext {

    typealias ContextClosure<T> = () throws -> T
    typealias ContextCompletionClosure<T> = (T?, Error?) -> Void

    func performThrowing<T>(_ closure: @escaping ContextClosure<T>, completion: @escaping ContextCompletionClosure<T>) {

        perform {
            do {
                let value = try closure()
                completion(value, nil)
            } catch {
                completion(nil, error)
            }
        }
    }

    func performThrowingAndWait<T>(_ closure: @escaping ContextClosure<T>) throws -> T {

        // swiftlint:disable:next implicitly_unwrapped_optional
        var value: T!
        var error: Error?

        performAndWait {
            do {
                value = try closure()
            } catch let closureError {
                error = closureError
            }
        }

        if let error = error {
            throw error
        }

        return value
    }

}

// MARK: - persistChanges

public extension NSManagedObjectContext {

    func persistChanges(_ description: String, saveParent: Bool = true, waitForParent: Bool = false) throws {

        guard hasChanges else { return }

        do {
            try save()
        } catch let error {
            // FIXME: use proper logging function when available
            print("💥[Alicerce.NSManagedObjectContext]: Error saving context \(self) (\(description)): \(error). " +
                  "Rolling back all changes...")

            rollback()
            throw error
        }

        guard saveParent, let parent = parent else { return }

        var parentError: Error?

        let parentSave = {
            guard parent.hasChanges else { return }

            do {
                try parent.save()
            } catch let error {
                // FIXME: use proper logging function when available
                print("💥[Alicerce.NSManagedObjectContext]: Error saving parent context \(self) (\(description)): " +
                      "\(error). Rolling back all changes...")
                parent.rollback()
                parentError = error
            }
        }

        waitForParent
            ? parent.performAndWait(parentSave)
            : parent.perform(parentSave)

        if let parentError = parentError {
            throw parentError
        }
    }
}

// MARK: - Parent Coordinator & Store type

public extension NSManagedObjectContext {

    var topLevelPersistentStoreCoordinator: NSPersistentStoreCoordinator? {

        switch (persistentStoreCoordinator, parent) {
        case (let persistentStoreCoordinator?, _):
            return persistentStoreCoordinator
        case (_, let parent?):
            return parent.topLevelPersistentStoreCoordinator
        default:
            return nil
        }
    }

    var isSQLiteStoreBased: Bool {

        switch topLevelPersistentStoreCoordinator?.firstStoreType {
        case .sqlite?:
            return true
        default:
            return false
        }
    }
}

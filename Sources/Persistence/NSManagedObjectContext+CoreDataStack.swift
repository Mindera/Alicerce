//
//  NSManagedObjectContext+CoreDataStack.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 03/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

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
            }
            catch { completion(nil, error) }
        }
    }

    func performThrowingAndWait<T>(_ closure: @escaping ContextClosure<T>) throws -> T {
        var value: T!
        var error: Error?

        performAndWait {
            do { value = try closure() }
            catch let blockError { error = blockError }
        }

        if let error = error { throw error }
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
            print("Error saving context \(self) (\(description)): \(error). Rollbacking all changes...")

            rollback()
            throw error
        }

        guard saveParent, let parent = parent else { return }

        let parentSave = {
            guard parent.hasChanges else { return }

            do {
                try parent.save()
            } catch let error {
                // FIXME: use proper logging function when available
                print("Error saving parent context \(parent) (\(description)): \(error). Rollbacking all changes...")
                parent.rollback()
            }
        }

        waitForParent
            ? parent.performAndWait(parentSave)
            : parent.perform(parentSave)
    }
}

// MARK: - Parent Coordinator & Store type

public extension NSManagedObjectContext {

    func topLevelPersistentStoreCoordinator() -> NSPersistentStoreCoordinator {
        switch (persistentStoreCoordinator, parent) {
        case let (persistentStoreCoordinator?, _): return persistentStoreCoordinator
        case let (_, parent?): return parent.topLevelPersistentStoreCoordinator()
        default: fatalError("💥: Context doesn't have neither a `persistentStoreCoordinator` nor a `parent`!")
        }
    }

    func isSQLiteStoreBased() -> Bool {
        switch topLevelPersistentStoreCoordinator().firstStoreType() {
        case .sqLite: return true
        default: return false
        }
    }
}

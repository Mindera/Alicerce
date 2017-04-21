//
//  DiskMemoryPersistence.swift
//  Alicerce
//
//  Created by Luís Portela on 13/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

public protocol DiskMemoryPersistenceDelegate: class {
    func canEvictObject(for key: Persistence.Key) -> Bool
}

public final class DiskMemoryPersistence: Persistence {

    public typealias CompletionClosure<R> = (_ inner: () throws -> R) -> Void

    public struct Configuration {
        /// Disk size limit in bytes
        let diskLimit: UInt64
        /// Memory size limit in bytes
        let memLimit: UInt64
        /// Path to the persistence
        let path: String

        /// Set the operation Quality of Service for read and write operations
        /// The read value should be higher than write, otherwise it will fail
        /// Default Values:
        ///   - read = .userInitiated
        ///   - write = .utility
        var qos: (read: QualityOfService, write: QualityOfService) = (read: .userInitiated, write: .utility) {
            willSet {
                guard newValue.read.rawValue > newValue.write.rawValue else {
                    return assertionFailure("💥 read value should be higher than write")
                }
            }
        }
    }

    public enum Error: Swift.Error {
        case diskCacheDisabled
        case failedToRemoveFile(Swift.Error?)
        case fileNotCreated
    }

    private let cache = NSCache<NSString, NSData>()

    private let configuration: Configuration

    weak var delegate: DiskMemoryPersistenceDelegate?

    private var diskCacheEnabled: Bool = false

    private let readOperationQueue: OperationQueue = {
        $0.name = "com.mindera.alicerce.persistence.diskmem.read"
        return $0
    }(OperationQueue())
    private let writeOperationQueue: OperationQueue = {
        $0.name = "com.mindera.alicerce.persistence.diskmem.write"
        $0.maxConcurrentOperationCount = 1
        return $0
    }(OperationQueue())

    private let fileManager: FileManager = FileManager.default

    private var usedDiskSize: UInt64 = 0 // Size in bytes

    public init(configuration: Configuration) {
        self.configuration = configuration

        cache.totalCostLimit = Int(configuration.memLimit)

        readOperationQueue.qualityOfService = configuration.qos.read
        writeOperationQueue.qualityOfService = configuration.qos.write

        diskCacheEnabled = hasDiskCacheDirectory() || createDiskCacheDirectory()

        calculateUsedDiskSize()
    }

    // MARK: - Public Methods

    public func object(for key: Persistence.Key, completion: @escaping CompletionClosure<Data>) {
        if let data = cachedData(for: key) {
            return completion { data }
        }

        // TODO: Check for object on disk and cache it if don't available

        diskData(for: key) { [weak self] inner in
            do {
                let data = try inner()

                self?.setCachedData(data, for: key)

                completion { data }
            } catch {
                completion { throw error }
            }
        }
    }

    public func setObject(_ object: Data, for key: Persistence.Key, completion: @escaping CompletionClosure<Void>) {
        setCachedData(object, for: key)

        setDiskData(object, for: key, completion: completion)
    }

    public func removeObject(for key: Persistence.Key, completion: @escaping CompletionClosure<Void>) {
        removeCachedData(for: key)

        removeDiskData(for: key, completion: completion)
    }

    // MARK: - Private Methods

    // MARK: - NSCache Related Operations

    private func cachedData(for key: Persistence.Key) -> Data? {
        return cache.object(forKey: key.nsString) as Data?
    }

    private func setCachedData(_ data: Data, for key: Persistence.Key) {
        cache.setObject(data.nsData, forKey: key.nsString)
    }

    private func removeCachedData(for key: Persistence.Key) {
        cache.removeObject(forKey: key.nsString)
    }

    // MARK: - Disk Related Operations

    private func diskData(for key: Persistence.Key, completion: @escaping CompletionClosure<Data>) {
        guard diskCacheEnabled else { return completion { throw PersistenceError.other(Error.diskCacheDisabled) } }

        let readOperation = DiskMemoryBlockOperation() { [unowned self] in
            let path = self.diskPath(for: key)

            guard let fileData = self.fileManager.contents(atPath: path) else {
                return completion { throw PersistenceError.noObjectForKey }
            }

            completion { fileData }
        }

        readOperationQueue.addOperation(readOperation)
    }

    private func setDiskData(_ data: Data, for key: Persistence.Key, completion: @escaping CompletionClosure<Void>) {
        guard diskCacheEnabled else { return completion { throw PersistenceError.other(Error.diskCacheDisabled) } }

        let writeOperation = DiskMemoryBlockOperation() { [unowned self] in
            let path = self.diskPath(for: key)

            var isDir = ObjCBool(false)
            let fileExists = self.fileManager.fileExists(atPath: path, isDirectory: &isDir)

            guard isDir.boolValue == false else {
                return completion { throw PersistenceError.other(Error.fileNotCreated) }
            }

            guard self.fileManager.createFile(atPath: path, contents: data) else {
                return completion { throw PersistenceError.other(Error.fileNotCreated) }
            }

            if fileExists == false {
                self.usedDiskSize += UInt64(data.count)
            }

            completion { () }
        }

        let evictOperation = createEvictOperation()
        evictOperation.addDependency(writeOperation)

        writeOperationQueue.addOperation(writeOperation)
        writeOperationQueue.addOperation(evictOperation)
    }

    private func removeDiskData(for key: Persistence.Key, completion: @escaping CompletionClosure<Void>) {
        guard diskCacheEnabled else { return completion { throw PersistenceError.other(Error.diskCacheDisabled) } }

        let removeOperation = DiskMemoryBlockOperation() { [unowned self] in
            let path = self.diskPath(for: key)
            let fileURL = URL(fileURLWithPath: path)
            
            guard let fileSize = fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
                return completion { throw PersistenceError.other(Error.failedToRemoveFile(nil)) }
            }

            do {
                try self.remove(fileAtURL: fileURL, size: UInt64(fileSize))
            } catch let error {
                return completion { throw error }
            }

            completion { () }
        }

        writeOperationQueue.addOperation(removeOperation)
    }

    private func calculateUsedDiskSize() {
        let calculateUsedSizeOperation = DiskMemoryBlockOperation() { [weak self] in
            guard let strongSelf = self else { return }

            let urls = strongSelf.directoryContents(with: [.fileSizeKey])

            let fileSizes = urls.map {
                UInt64($0.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0)
            }

            strongSelf.usedDiskSize = fileSizes.reduce(UInt64(0), +)
        }

        writeOperationQueue.addOperation(calculateUsedSizeOperation)
    }

    private func diskPath(for key: Persistence.Key) -> String {
        return "\(configuration.path)/\(key)"
    }

    private func hasDiskCacheDirectory() -> Bool {
        return fileManager.fileExists(atPath: configuration.path)
    }

    // FIX: Should this error be propagated to the top level?
    private func createDiskCacheDirectory() -> Bool {
        do {
            try fileManager.createDirectory(atPath: configuration.path,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
        }
        catch let error {
            assertionFailure("💥 failed to create directory `\(configuration.path)` with error: \n\(error)")
            return false
        }

        return true
    }

    private func directoryContents(with keys: [URLResourceKey]) -> [URL] {
        let url = URL(fileURLWithPath: configuration.path, isDirectory: true)

        guard let urls = try? fileManager.contentsOfDirectory(at: url,
                                                              includingPropertiesForKeys: keys,
                                                              options: .skipsPackageDescendants)
            else {
                assertionFailure("💥 failed to read directory content for path 👉 \(url.absoluteString)")
                return []
        }

        return urls
    }
    
    private func remove(fileAtURL url: URL, size: UInt64) throws {
        do {
            try self.fileManager.removeItem(at: url)
            
            usedDiskSize -= size // Update used size if item removed with success
        } catch let error {
            throw PersistenceError.other(Error.failedToRemoveFile(error))
        }
    }

    // MARK: - Operations

    private func createEvictOperation() -> DiskMemoryBlockOperation {
        return DiskMemoryBlockOperation() { [unowned self] in

            // Check if should run eviction
            guard self.configuration.diskLimit < self.usedDiskSize else {
                return
            }

            let extraOccupiedDiskSize = self.usedDiskSize - self.configuration.diskLimit

            let urls = self.directoryContents(with: [.contentAccessDateKey, .fileSizeKey])

            typealias FileAccessTimeSizeTuple = (accessTime: TimeInterval, size: UInt64)
            typealias FileURLAttributesTuple = (url: URL, fileAttr: FileAccessTimeSizeTuple)

            let fileAttributes: [FileURLAttributesTuple] = urls.map {
                let resourceValue = $0.resourceValues(forKeys: [.contentAccessDateKey, .fileSizeKey])

                return ($0, (resourceValue.contentAccessDate?.timeIntervalSince1970 ?? 0, UInt64(resourceValue.fileSize ?? 0)))
                }.sorted { $0.fileAttr.accessTime > $1.fileAttr.accessTime }

            var evictSize: UInt64 = 0

            let filesToRemove = fileAttributes.prefix {
                guard evictSize < extraOccupiedDiskSize else {
                    return false
                }

                evictSize += $0.fileAttr.size

                return true
            }

            filesToRemove.forEach {
                guard let _ = try? self.remove(fileAtURL: $0.url, size: $0.fileAttr.size) else {
                    assertionFailure("💥 Failed to remove file with path 👉 \($0)")

                    return print("💥 Failed to remove file with path 👉 \($0)")
                }
            }
        }
    }
}

fileprivate final class DiskMemoryBlockOperation: BlockOperation {
    
    required init(qos: QualityOfService = .default, block: @escaping () -> Swift.Void) {
        super.init()
        
        addExecutionBlock(block)
        qualityOfService = qos
    }
}

//
//  DiskMemoryPersistenceStack.swift
//  Alicerce
//
//  Created by Luís Portela on 13/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

public protocol DiskMemoryPersistenceStackDelegate: class {
    func canEvictObject(for key: Persistence.Key) -> Bool
}

public final class DiskMemoryPersistenceStack: NSObject, PersistenceStack {

    public struct PersistencePerformanceMetrics {

        let metrics: PerformanceMetrics
        let memoryAttributeKey: String
        let diskAttributeKey: String
        let readMemoryEventKey: String
        let writeMemoryEventKey: String
        let readDiskEventKey: String
        let writeDiskEventKey: String

        public init(metrics: PerformanceMetrics,
                    memoryAttributeKey: String,
                    diskAttributeKey: String,
                    readMemoryEventKey: String,
                    writeMemoryEventKey: String,
                    readDiskEventKey: String,
                    writeDiskEventKey: String) {

            self.metrics = metrics
            self.memoryAttributeKey = memoryAttributeKey
            self.diskAttributeKey = diskAttributeKey
            self.readMemoryEventKey = readMemoryEventKey
            self.writeMemoryEventKey = writeMemoryEventKey
            self.readDiskEventKey = readDiskEventKey
            self.writeDiskEventKey = writeDiskEventKey
        }
    }

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

        public init(diskLimit: UInt64,
                    memLimit: UInt64,
                    path: String,
                    qos: (read: QualityOfService, write: QualityOfService) = (read: .userInitiated, write: .utility)) {

            self.diskLimit = diskLimit
            self.memLimit = memLimit
            self.path = path
            self.qos = qos
        }
    }

    public enum Error: Swift.Error {
        case diskCacheDisabled
        case failedToRemoveFile(Swift.Error?)
        case fileNotCreated
    }

    private let cache = NSCache<NSString, NSData>()

    private let configuration: Configuration

    weak var delegate: DiskMemoryPersistenceStackDelegate?

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
    private var usedMemorySize: UInt64 = 0 // Size in bytes

    private let persistencePerformanceMetrics: PersistencePerformanceMetrics?

    public init(configuration: Configuration,
                persistencePerformanceMetrics: PersistencePerformanceMetrics? = nil) {
        self.configuration = configuration
        self.persistencePerformanceMetrics = persistencePerformanceMetrics

        super.init()

        cache.totalCostLimit = Int(configuration.memLimit)
        cache.delegate = self

        readOperationQueue.qualityOfService = configuration.qos.read
        writeOperationQueue.qualityOfService = configuration.qos.write

        diskCacheEnabled = hasDiskCacheDirectory() || createDiskCacheDirectory()

        calculateUsedDiskSize()
    }

    // MARK: - Public Methods

    public func object(for key: Persistence.Key, completion: @escaping PersistenceCompletionClosure<Data>) {
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

    public func setObject(_ object: Data, for key: Persistence.Key, completion: @escaping PersistenceCompletionClosure<Void>) {
        setCachedData(object, for: key)

        setDiskData(object, for: key, completion: completion)
    }

    public func removeObject(for key: Persistence.Key, completion: @escaping PersistenceCompletionClosure<Void>) {
        removeCachedData(for: key)

        removeDiskData(for: key, completion: completion)
    }

    // MARK: - Private Methods

    // MARK: - NSCache Related Operations

    private func cachedData(for key: Persistence.Key) -> Data? {

        let identifier = persistencePerformanceMetrics?.readMemoryEventKey ?? ""

        persistencePerformanceMetrics?.metrics.begin(with: identifier)
        let data = cache.object(forKey: key.nsString) as Data?
        persistencePerformanceMetrics?.metrics.end(with: identifier)

        return data
    }

    private func setCachedData(_ data: Data, for key: Persistence.Key) {

        let identifier = persistencePerformanceMetrics?.writeMemoryEventKey ?? ""
        let attribute = persistencePerformanceMetrics?.memoryAttributeKey ?? ""

        persistencePerformanceMetrics?.metrics.begin(with: identifier)
        cache.setObject(data.nsData, forKey: key.nsString)
        usedMemorySize += UInt64(data.count)
        persistencePerformanceMetrics?.metrics.end(with: identifier, metadata: [attribute : usedMemorySize])
    }

    private func removeCachedData(for key: Persistence.Key) {
        cache.removeObject(forKey: key.nsString)
    }

    // MARK: - Disk Related Operations

    private func diskData(for key: Persistence.Key, completion: @escaping PersistenceCompletionClosure<Data>) {
        guard diskCacheEnabled else { return completion { throw Persistence.Error.other(Error.diskCacheDisabled) } }

        let identifier = persistencePerformanceMetrics?.readDiskEventKey ?? ""

        persistencePerformanceMetrics?.metrics.begin(with: identifier)

        let readOperation = DiskMemoryBlockOperation() { [unowned self] in
            let path = self.diskPath(for: key)

            guard let fileData = self.fileManager.contents(atPath: path) else {
                return completion { throw Persistence.Error.noObjectForKey }
            }

            completion { [weak self] in
                self?.persistencePerformanceMetrics?.metrics.end(with: identifier)

                return fileData
            }
        }

        readOperationQueue.addOperation(readOperation)
    }

    private func setDiskData(_ data: Data,
                             for key: Persistence.Key,
                             completion: @escaping PersistenceCompletionClosure<Void>) {
        guard diskCacheEnabled else { return completion { throw Persistence.Error.other(Error.diskCacheDisabled) } }

        let identifier = persistencePerformanceMetrics?.writeDiskEventKey ?? ""

        persistencePerformanceMetrics?.metrics.begin(with: identifier)

        let writeOperation = DiskMemoryBlockOperation() { [unowned self] in
            let path = self.diskPath(for: key)

            var isDir = ObjCBool(false)
            let fileExists = self.fileManager.fileExists(atPath: path, isDirectory: &isDir)

            guard isDir.boolValue == false else {
                return completion { throw Persistence.Error.other(Error.fileNotCreated) }
            }

            guard self.fileManager.createFile(atPath: path, contents: data) else {
                return completion { throw Persistence.Error.other(Error.fileNotCreated) }
            }

            if fileExists == false {
                self.usedDiskSize += UInt64(data.count)
            }

            completion { [weak self] in

                guard let strongSelf = self,
                    let persistencePerformanceMetrics = strongSelf.persistencePerformanceMetrics else { return }
                
                persistencePerformanceMetrics.metrics.end(
                    with: identifier,
                    metadata: [persistencePerformanceMetrics.diskAttributeKey : strongSelf.usedDiskSize]
                )

                return
            }
        }

        let evictOperation = createEvictOperation()
        evictOperation.addDependency(writeOperation)

        writeOperationQueue.addOperation(writeOperation)
        writeOperationQueue.addOperation(evictOperation)
    }

    private func removeDiskData(for key: Persistence.Key, completion: @escaping PersistenceCompletionClosure<Void>) {
        guard diskCacheEnabled else { return completion { throw Persistence.Error.other(Error.diskCacheDisabled) } }

        let removeOperation = DiskMemoryBlockOperation() { [unowned self] in
            let path = self.diskPath(for: key)
            let fileURL = URL(fileURLWithPath: path)
            
            guard let fileSize = fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
                return completion { throw Persistence.Error.other(Error.failedToRemoveFile(nil)) }
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
            throw Persistence.Error.other(Error.failedToRemoveFile(error))
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

extension DiskMemoryPersistenceStack: NSCacheDelegate {

    public func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {

        guard let data = obj as? Data else {
            assertionFailure("💥 Failed to identify object in cache as data 👉 \(obj)")
            return
        }

        usedMemorySize -= UInt64(data.count)
    }
}

fileprivate final class DiskMemoryBlockOperation: BlockOperation {
    
    required init(qos: QualityOfService = .default, block: @escaping () -> Swift.Void) {
        super.init()
        
        addExecutionBlock(block)
        qualityOfService = qos
    }
}

//
//  DiskMemoryPersistenceStack.swift
//  Alicerce
//
//  Created by Luís Portela on 13/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

public final class DiskMemoryPersistenceStack: NSObject, PersistenceStack {

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
        var qos: (read: QualityOfService, write: QualityOfService) {
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
        case failedToRemoveFile(FileRemovalError)
        case failedToCreateFile(FileCreationError)

        public enum FileRemovalError: Swift.Error {
            case fileResourceValuesFetchFailed(Swift.Error)
            case invalidFileTypeAtPath(String)
            case fileNotFound(Swift.Error)
            case removeFailed(Swift.Error)
        }

        public enum FileCreationError: Swift.Error {
            case fileResourceValuesFetchFailed(Swift.Error)
            case invalidFileTypeAtPath(String)
            case createFailed
        }
    }

    private let cache = NSCache<NSString, NSData>()

    private let configuration: Configuration

    private var diskCacheEnabled: Bool = false

    let readOperationQueue: OperationQueue = {
        $0.name = "com.mindera.alicerce.persistence.diskmem.read"
        return $0
    }(OperationQueue())
    let writeOperationQueue: OperationQueue = {
        $0.name = "com.mindera.alicerce.persistence.diskmem.write"
        $0.maxConcurrentOperationCount = 1
        return $0
    }(OperationQueue())

    private let fileManager: FileManager = .default

    private var usedDiskSize: UInt64 = 0 // Size in bytes

    // needs to be atomic since `NSCache` operations are not always made on the same queue/thread, i.e. caller
    private let usedMemorySize = Atomic<UInt64>(0) // Size in bytes

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

    public func setObject(_ object: Data,
                          for key: Persistence.Key,
                          completion: @escaping PersistenceCompletionClosure<Void>) {
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
        persistencePerformanceMetrics?.beginReadMemory()
        let data = cache.object(forKey: key.nsString) as Data?
        persistencePerformanceMetrics?.endReadMemory()

        return data
    }

    private func setCachedData(_ data: Data, for key: Persistence.Key) {
        persistencePerformanceMetrics?.beginWriteMemory()
        let blobSize = data.count
        // update *before* setting new blob because we can trigger an eviction on set if the cache is full or small
        usedMemorySize.modify { $0 += UInt64(blobSize) }
        cache.setObject(data.nsData, forKey: key.nsString, cost: blobSize)
        persistencePerformanceMetrics?.endWriteMemory(blobSize: UInt64(blobSize), memorySize: usedMemorySize.value)
    }

    private func removeCachedData(for key: Persistence.Key) {
        cache.removeObject(forKey: key.nsString)
    }

    // MARK: - Disk Related Operations

    private func diskData(for key: Persistence.Key, completion: @escaping PersistenceCompletionClosure<Data>) {
        guard diskCacheEnabled else { return completion { throw Persistence.Error.other(Error.diskCacheDisabled) } }

        persistencePerformanceMetrics?.beginReadDisk()

        let readOperation = DiskMemoryBlockOperation { [unowned self] in
            let path = self.diskPath(for: key)

            guard let fileData = self.fileManager.contents(atPath: path) else {
                return completion { [weak self] in
                    self?.persistencePerformanceMetrics?.endReadDisk()
                    throw Persistence.Error.noObjectForKey
                }
            }

            completion { [weak self] in
                self?.persistencePerformanceMetrics?.endReadDisk()
                return fileData
            }
        }

        readOperationQueue.addOperation(readOperation)
    }

    private func setDiskData(_ data: Data,
                             for key: Persistence.Key,
                             completion: @escaping PersistenceCompletionClosure<Void>) {
        guard diskCacheEnabled else { return completion { throw Persistence.Error.other(Error.diskCacheDisabled) } }

        persistencePerformanceMetrics?.beginWriteDisk()

        let writeOperation = DiskMemoryBlockOperation { [unowned self] in
            let path = self.diskPath(for: key)
            let fileURL = URL(fileURLWithPath: path)

            var existingFileSize: UInt64 = 0

            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileResourceTypeKey, .fileSizeKey])

                switch resourceValues.fileResourceType {
                case .regular?:
                    existingFileSize = UInt64(resourceValues.fileSize ?? 0)
                default:
                    return completion {
                        throw Persistence.Error.other(Error.failedToCreateFile(.invalidFileTypeAtPath(path)))
                    }
                }
            } catch let error as NSError where error.isNoSuchFileError {
                // ignore, file doesn't exist
            } catch {
                return completion {
                    throw Persistence.Error.other(Error.failedToCreateFile(.fileResourceValuesFetchFailed(error)))
                }
            }

            // create the file, which will overwrite any existing file at the same path
            guard self.fileManager.createFile(atPath: path, contents: data) else {
                return completion { throw Persistence.Error.other(Error.failedToCreateFile(.createFailed)) }
            }

            do {
                // fetch the new file's size from the file system, because it can be different from the blob's size
                let newResourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                let newFileSize = UInt64(newResourceValues.fileSize ?? 0)

                // subtract the size of any (overwritten) existing file from the new file's size
                self.usedDiskSize += newFileSize - existingFileSize

                completion { [weak self] in
                    guard let strongSelf = self else { return }

                    strongSelf.persistencePerformanceMetrics?.endWriteDisk(blobSize: newFileSize,
                                                                           diskSize: strongSelf.usedDiskSize)
                }
            } catch {
                return completion {
                    throw Persistence.Error.other(Error.failedToCreateFile(.fileResourceValuesFetchFailed(error)))
                }
            }
        }

        let evictOperation = createEvictOperation()
        evictOperation.addDependency(writeOperation)

        writeOperationQueue.addOperation(writeOperation)
        writeOperationQueue.addOperation(evictOperation)
    }

    private func removeDiskData(for key: Persistence.Key, completion: @escaping PersistenceCompletionClosure<Void>) {
        guard diskCacheEnabled else { return completion { throw Persistence.Error.other(Error.diskCacheDisabled) } }

        let removeOperation = DiskMemoryBlockOperation { [unowned self] in
            let path = self.diskPath(for: key)
            let fileURL = URL(fileURLWithPath: path)

            var resourceValues: URLResourceValues? = nil

            do {
                resourceValues = try fileURL.resourceValues(forKeys: [.fileResourceTypeKey, .fileSizeKey])

                var fileSize: UInt64 = 0

                switch resourceValues?.fileResourceType {
                case .regular?:
                    fileSize = UInt64(resourceValues?.fileSize ?? 0)
                default:
                    return completion {
                        throw Persistence.Error.other(Error.failedToRemoveFile(.invalidFileTypeAtPath(path)))
                    }
                }

                try self.remove(fileAtURL: fileURL, size: fileSize)

            } catch let error as NSError where error.isNoSuchFileError {
                return completion { throw Persistence.Error.other(Error.failedToRemoveFile(.fileNotFound(error))) }
            } catch let error as Persistence.Error {
                return completion { throw error }
            } catch {
                return completion {
                    throw Persistence.Error.other(Error.failedToRemoveFile(.fileResourceValuesFetchFailed(error)))
                }
            }

            completion { () }
        }

        writeOperationQueue.addOperation(removeOperation)
    }

    private func calculateUsedDiskSize() {
        let calculateUsedSizeOperation = DiskMemoryBlockOperation { [weak self] in
            guard let strongSelf = self else { return }

            let urls = strongSelf.directoryContents(with: [.fileSizeKey])

            strongSelf.usedDiskSize = urls.reduce(0) {
                guard let fileSize = try? $1.resourceValues(forKeys: [.fileSizeKey]).fileSize else { return $0 }
                return $0 + UInt64(fileSize ?? 0)
            }
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
        } catch let error {
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
            throw Persistence.Error.other(Error.failedToRemoveFile(.removeFailed(error)))
        }
    }

    // MARK: - Operations

    private func createEvictOperation() -> DiskMemoryBlockOperation {
        return DiskMemoryBlockOperation { [unowned self] in

            // Check if should run eviction
            guard self.configuration.diskLimit < self.usedDiskSize else { return }

            let extraOccupiedDiskSize = self.usedDiskSize - self.configuration.diskLimit

            let urls = self.directoryContents(with: [.contentAccessDateKey, .fileSizeKey])

            typealias FileAccessTimeSizeTuple = (accessTime: TimeInterval, size: UInt64)
            typealias FileURLAttributesTuple = (url: URL, fileAttr: FileAccessTimeSizeTuple)

            let fileAttributes: [FileURLAttributesTuple] = urls
                .map {
                    let resourceValue = try? $0.resourceValues(forKeys: [.contentAccessDateKey, .fileSizeKey])

                    return ($0, (resourceValue?.contentAccessDate?.timeIntervalSince1970 ?? 0,
                                 UInt64(resourceValue?.fileSize ?? 0)))
                }
                .sorted { $0.fileAttr.accessTime < $1.fileAttr.accessTime } // sort by *less recently accessed* first

            var evictSize: UInt64 = 0

            let filesToRemove = fileAttributes.prefix {
                guard evictSize < extraOccupiedDiskSize else { return false }

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

        // this delegate method is invoked from the queue/thread where a new object is set when it causes an eviction.

        guard let data = obj as? Data else {
            assertionFailure("💥 Failed to identify object in cache as data 👉 \(obj)")
            return
        }

        usedMemorySize.modify { $0 -= UInt64(data.count) }
    }
}

fileprivate final class DiskMemoryBlockOperation: BlockOperation {

    required init(qos: QualityOfService = .default, block: @escaping () -> Swift.Void) {
        super.init()

        addExecutionBlock(block)
        qualityOfService = qos
    }
}

private extension NSError {

    var isNoSuchFileError: Bool { return domain == NSCocoaErrorDomain && code == NSFileReadNoSuchFileError }
}

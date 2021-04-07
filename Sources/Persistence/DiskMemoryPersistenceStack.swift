// swiftlint:disable file_length
import UIKit

#if canImport(AlicerceCore) && canImport(AlicerceLogging)
import AlicerceCore
import AlicerceLogging
#endif

public extension Persistence {

    final class DiskMemoryPersistenceStack: NSObject, PersistenceStack {

        public typealias Key = String

        public struct Configuration {

            /// Disk size limit in bytes.
            let diskLimit: UInt64

            /// Memory size limit in bytes.
            let memLimit: UInt64

            /// Path where the data is persisted.
            let path: String

            /// The manager used for file operations.
            let fileManager: FileManager

            /// The performance metrics tracker.
            let performanceMetrics: PersistencePerformanceMetricsTracker?

            /// The queue to use for read operations. Set to `nil` for synchronous reads.
            let readQueue: DispatchQueue?

            /// The underlying queue to use for write operations (i.e. by the `writeOperationQueue`).
            let writeQueue: DispatchQueue

            public init(diskLimit: UInt64,
                        memLimit: UInt64,
                        path: String,
                        fileManager: FileManager = .default,
                        performanceMetrics: PersistencePerformanceMetricsTracker? = nil,
                        readQueue: DispatchQueue?,
                        writeQueue: DispatchQueue) {

                self.diskLimit = diskLimit
                self.memLimit = memLimit
                self.path = path
                self.fileManager = fileManager
                self.performanceMetrics = performanceMetrics
                self.readQueue = readQueue
                self.writeQueue = writeQueue
            }
        }

        public enum Error: Swift.Error {
            case failedToCreateDirectory(Swift.Error)
            case failedToGetDirectoryContents(Swift.Error)
            case failedToRemoveFile(FileRemovalError)
            case failedToCreateFile(FileCreationError)
            case failedToRemoveAll(RemoveAllError)

            public enum FileRemovalError: Swift.Error {
                case fileResourceValuesFetchFailed(Swift.Error)
                case invalidFileTypeAtPath(String)
                case removeFailed(Swift.Error)
            }

            public enum FileCreationError: Swift.Error {
                case fileResourceValuesFetchFailed(Swift.Error)
                case invalidFileTypeAtPath(String)
                case createFailed
            }

            public enum RemoveAllError: Swift.Error {
                case removeDirectoryFailed(Swift.Error)
                case createDirectoryFailed(Swift.Error)
            }
        }

        typealias Bytes = UInt64

        typealias MemoryAccessStopClosure = (_ result: Result<(blobSize: Bytes, memorySize: Bytes), Error>) -> Void

        typealias DiskAccessStopClosure = (_ result: Result<(blobSize: Bytes, diskSize: Bytes), Error>) -> Void

        private let cache = NSCache<NSString, NSData>()

        private let configuration: Configuration

        private var readQueue: DispatchQueue? { return configuration.readQueue }

        private let writeOperationQueue: OperationQueue = {
            $0.name = "com.mindera.alicerce.persistence.diskmem.write.operation-queue"
            $0.maxConcurrentOperationCount = 1
            return $0
        }(OperationQueue())

        // needs to be atomic since read and write operations are not always made on the same queue/thread
        private var usedDiskSize = Atomic<Bytes>(0)

        // needs to be atomic since `NSCache` operations are not always made on the same queue/thread, i.e. caller
        private let usedMemorySize = Atomic<Bytes>(0)

        public init(configuration: Configuration) throws {
            self.configuration = configuration

            super.init()

            cache.totalCostLimit = Int(configuration.memLimit)
            cache.delegate = self

            writeOperationQueue.underlyingQueue = configuration.writeQueue

            if hasDiskCacheDirectory() == false {
                try createDiskCacheDirectory()
            }

            usedDiskSize.value = try calculateUsedDiskSize()
        }

        deinit {
            writeOperationQueue.waitUntilAllOperationsAreFinished()
        }

        // MARK: - Public Methods

        public func object(for key: Key, completion: @escaping ReadCompletionClosure) {
            if let data = cachedData(for: key) {
                return completion(.success(data))

                // TODO: Check for object on disk and persist it if not present, because it might have been evicted.
                // This is to ensure that the most accessed data is present on both caches
                // Ideally we could even check that the data was the same, and simply "touch" the file to update the
                // last accessed date (essentially moving it to the end of the eviction "queue").
            }

            diskData(for: key) { [weak self] in
                completion($0)

                switch $0 {
                case .success(let data?): self?.setCachedData(data, for: key)
                default: break
                }
            }
        }

        public func setObject(_ object: Data, for key: Key, completion: @escaping WriteCompletionClosure) {
            setCachedData(object, for: key)

            setDiskData(object, for: key, completion: completion)
        }

        public func removeObject(for key: Key, completion: @escaping WriteCompletionClosure) {
            removeCachedData(for: key)

            removeDiskData(for: key, completion: completion)
        }

        public func removeAll(completion: @escaping WriteCompletionClosure) {
            cache.removeAllObjects()

            assert(usedMemorySize.value == 0, "🔥 Total Used Memory should be 0 after `removeAllObjects()`!")

            let removeAllOperation = makeRemoveAllOperation(completion: completion)
            writeOperationQueue.addOperation(removeAllOperation)
        }

        // MARK: - Private Methods

        // MARK: - NSCache Related Operations

        private func cachedData(for key: Key) -> Data? {
            guard let performanceMetrics = configuration.performanceMetrics else {
                return cache.object(forKey: key.nsString) as Data?
            }

            return performanceMetrics.measureMemoryRead { [unowned self] (stop: @escaping MemoryAccessStopClosure) in
                let cached = self.cache.object(forKey: key.nsString) as Data?

                switch cached {
                case let value?: stop(.success((UInt64(value.count), usedMemorySize.value)))
                case nil: stop(.success((0, usedMemorySize.value)))
                }

                return cached
            }
        }

        private func setCachedData(_ data: Data, for key: Key) {
            guard let performanceMetrics = configuration.performanceMetrics else {
                let blobSize = data.count
                // update *before* setting new blob because we can trigger an eviction on set if the cache is full/small
                usedMemorySize.modify { $0 += UInt64(blobSize) }
                cache.setObject(data.nsData, forKey: key.nsString, cost: blobSize)
                return
            }

            performanceMetrics.measureMemoryWrite { (stop: @escaping MemoryAccessStopClosure) in
                let blobSize = data.count
                // update *before* setting new blob because we can trigger an eviction on set if the cache is full/small
                let newUsedMemorySize: UInt64 = self.usedMemorySize.modify {
                    $0 += UInt64(blobSize)
                    return $0
                }
                cache.setObject(data.nsData, forKey: key.nsString, cost: blobSize)

                stop(.success((UInt64(blobSize), newUsedMemorySize)))
            }
        }

        private func removeCachedData(for key: Key) {
            cache.removeObject(forKey: key.nsString)
        }

        // MARK: - Disk Related Operations

        private func diskData(for key: Key, completion: @escaping ReadCompletionClosure) {
            guard let performanceMetrics = configuration.performanceMetrics else {
                let read = makeReadClosure(for: key, completion: completion)

                readQueue?.async(execute: read) ?? read()
                return
            }

            performanceMetrics.measureDiskRead { (stop: @escaping DiskAccessStopClosure) in
                let read = makeReadClosure(for: key, completion: completion, metricStop: stop)

                readQueue?.async(execute: read) ?? read()
            }
        }

        private func setDiskData(_ data: Data, for key: Key, completion: @escaping WriteCompletionClosure) {
            let writeOperation: DiskMemoryBlockOperation

            if let performanceMetrics = configuration.performanceMetrics {
                writeOperation = performanceMetrics.measureDiskWrite { [unowned self] stop in
                    self.makeWriteOperation(with: data, for: key, completion: completion, metricStop: stop)
                }
            } else {
                writeOperation = makeWriteOperation(with: data, for: key, completion: completion)
            }

            let evictOperation = makeEvictOperation()
            evictOperation.addDependency(writeOperation)

            writeOperationQueue.addOperation(writeOperation)
            writeOperationQueue.addOperation(evictOperation)
        }

        private func removeDiskData(for key: Key, completion: @escaping WriteCompletionClosure) {
            let removeOperation = DiskMemoryBlockOperation { [unowned self] in
                let path = self.diskPath(for: key)
                let fileURL = URL(fileURLWithPath: path)

                var resourceValues: URLResourceValues?

                do {
                    resourceValues = try fileURL.resourceValues(forKeys: [.fileResourceTypeKey, .fileSizeKey])

                    var fileSize: UInt64 = 0

                    switch resourceValues?.fileResourceType {
                    case .regular?:
                        fileSize = UInt64(resourceValues?.fileSize ?? 0)
                    default:
                        return completion(.failure(.failedToRemoveFile(.invalidFileTypeAtPath(path))))
                    }

                    try self.remove(fileAtURL: fileURL, size: fileSize)

                } catch let error as NSError where error.isNoSuchFileError {
                    return completion(.success(())) // file might have been evicted already
                } catch let error as Error {
                    return completion(.failure(error))
                } catch {
                    return completion(.failure(.failedToRemoveFile(.fileResourceValuesFetchFailed(error))))
                }

                completion(.success(()))
            }

            writeOperationQueue.addOperation(removeOperation)
        }

        private func calculateUsedDiskSize() throws -> UInt64 {
            let urls = try directoryContents(with: [.fileSizeKey])

            return urls.reduce(into: 0) {
                guard let fileSize = try? $1.resourceValues(forKeys: [.fileSizeKey]).fileSize else { return }
                $0 += UInt64(fileSize)
            }
        }

        private func diskPath(for key: Key) -> String {
            return "\(configuration.path)/\(key)"
        }

        private func hasDiskCacheDirectory() -> Bool {
            return configuration.fileManager.fileExists(atPath: configuration.path)
        }

        private func createDiskCacheDirectory() throws {
            do {
                try configuration.fileManager.createDirectory(atPath: configuration.path,
                                                              withIntermediateDirectories: true,
                                                              attributes: nil)
            } catch {
                throw Error.failedToCreateDirectory(error)
            }
        }

        private func directoryContents(with keys: [URLResourceKey]) throws -> [URL] {
            let url = URL(fileURLWithPath: configuration.path, isDirectory: true)

            do {
                return try configuration.fileManager.contentsOfDirectory(at: url,
                                                                         includingPropertiesForKeys: keys,
                                                                         options: .skipsPackageDescendants)
            } catch {
                throw Error.failedToGetDirectoryContents(error)
            }
        }

        private func remove(fileAtURL url: URL, size: UInt64) throws {
            do {
                try configuration.fileManager.removeItem(at: url)

                usedDiskSize.modify { $0 -= size } // Update used size if item removed with success
            } catch let error {
                throw Error.failedToRemoveFile(.removeFailed(error))
            }
        }

        // MARK: - Operations

        private func makeReadClosure(for key: Key,
                                     completion: @escaping ReadCompletionClosure,
                                     metricStop: (DiskAccessStopClosure)? = nil) -> () -> Void {
            return { [unowned self] in
                let path = self.diskPath(for: key)

                let fileData = self.configuration.fileManager.contents(atPath: path)
                let size = fileData.flatMap { UInt64($0.count) } ?? 0

                metricStop?(.success((size, self.usedDiskSize.value)))
                completion(.success(fileData))
            }
        }

        private func makeWriteOperation(with data: Data,
                                        for key: Key,
                                        completion: @escaping WriteCompletionClosure,
                                        metricStop: (DiskAccessStopClosure)? = nil) -> DiskMemoryBlockOperation {
            return DiskMemoryBlockOperation { [unowned self] in
                let path = self.diskPath(for: key)
                let fileURL = URL(fileURLWithPath: path)

                var existingFileSize: UInt64 = 0

                func fail(with error: Error) {
                    metricStop?(.failure(error))
                    completion(.failure(error))
                }

                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.fileResourceTypeKey, .fileSizeKey])

                    switch resourceValues.fileResourceType {
                    case .regular?:
                        existingFileSize = UInt64(resourceValues.fileSize ?? 0)
                    default:
                        fail(with: .failedToCreateFile(.invalidFileTypeAtPath(path)))
                        return
                    }
                } catch let error as NSError where error.isNoSuchFileError {
                    // ignore, file doesn't exist
                } catch {
                    fail(with: .failedToCreateFile(.fileResourceValuesFetchFailed(error)))
                    return
                }

                // create the file, which will overwrite any existing file at the same path
                guard self.configuration.fileManager.createFile(atPath: path, contents: data) else {
                    fail(with: .failedToCreateFile(.createFailed))
                    return
                }

                do {
                    // fetch the new file's size from the file system, because it can be different from the blob's size
                    let newResourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                    let newFileSize = UInt64(newResourceValues.fileSize ?? 0)

                    // subtract the size of any (overwritten) existing file from the new file's size
                    let usedDiskSize: UInt64 = self.usedDiskSize.modify {
                        $0 += newFileSize - existingFileSize
                        return $0
                    }

                    metricStop?(.success((newFileSize, usedDiskSize)))
                    completion(.success(()))
                } catch {
                    fail(with: .failedToCreateFile(.fileResourceValuesFetchFailed(error)))
                    return
                }
            }
        }

        private func makeEvictOperation() -> DiskMemoryBlockOperation {
            return DiskMemoryBlockOperation { [unowned self] in

                // Check if should run eviction
                let usedDiskSize = self.usedDiskSize.value

                guard self.configuration.diskLimit < usedDiskSize else { return }

                let extraOccupiedDiskSize = usedDiskSize - self.configuration.diskLimit

                guard let urls = try? self.directoryContents(with: [.contentAccessDateKey, .fileSizeKey]) else {
                    assertionFailure("💥 Failed to get directory contents on evict!")
                    Log.internalLogger.error("💥 Failed to get directory contents on evict!")
                    return
                }

                typealias FileAccessTimeSizeTuple = (accessTime: TimeInterval, size: UInt64)
                typealias FileURLAttributesTuple = (url: URL, fileAttr: FileAccessTimeSizeTuple)

                let fileAttributes: [FileURLAttributesTuple] = urls
                    .map {
                        let resourceValue = try? $0.resourceValues(forKeys: [.contentAccessDateKey, .fileSizeKey])

                        return ($0, (resourceValue?.contentAccessDate?.timeIntervalSince1970 ?? 0,
                                     UInt64(resourceValue?.fileSize ?? 0)))
                    }
                    .sorted { $0.fileAttr.accessTime < $1.fileAttr.accessTime }
                    // sort by *less recently accessed* first

                var evictSize: UInt64 = 0

                let filesToRemove = fileAttributes.prefix {
                    guard evictSize < extraOccupiedDiskSize else { return false }

                    evictSize += $0.fileAttr.size

                    return true
                }

                filesToRemove.forEach {
                    do {
                        try self.remove(fileAtURL: $0.url, size: $0.fileAttr.size)
                    } catch {
                        assertionFailure("💥 Failed to remove file with at: \($0) with error: \(error)")
                        Log.internalLogger.error("💥 Failed to remove file at: \($0) with error: \(error)")
                    }
                }
            }
        }

        private func makeRemoveAllOperation(completion: @escaping WriteCompletionClosure) -> DiskMemoryBlockOperation {
            return DiskMemoryBlockOperation { [unowned self] in

                let configuration = self.configuration

                do {
                    try configuration.fileManager.removeItem(atPath: configuration.path)
                } catch {
                    completion(.failure(.failedToRemoveAll(.removeDirectoryFailed(error))))
                    return
                }

                self.usedDiskSize.value = 0

                do {
                    try configuration.fileManager.createDirectory(atPath: configuration.path,
                                                                  withIntermediateDirectories: true,
                                                                  attributes: nil)
                } catch {
                    completion(.failure(.failedToRemoveAll(.createDirectoryFailed(error))))
                    return
                }

                completion(.success(()))
            }
        }
    }
}

extension Persistence.DiskMemoryPersistenceStack: NSCacheDelegate {

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

    var isNoSuchFileError: Bool {
        return domain == NSCocoaErrorDomain && (code == NSFileReadNoSuchFileError || code == NSFileNoSuchFileError)
    }
}

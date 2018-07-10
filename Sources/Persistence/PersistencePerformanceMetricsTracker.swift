import Foundation
import Result

public protocol PersistencePerformanceMetricsTracker: PerformanceMetricsTracker {

    /// A closure to be used when stopping measuring memory reads/writes.
    typealias MemoryAccessStopClosure<E: Error> = (_ result: Result<(blobSize: UInt64, memorySize: UInt64), E>) -> Void

    /// A closure to be used when stopping measuring disk reads/writes.
    typealias DiskAccessStopClosure<E: Error> = (_ result: Result<(blobSize: UInt64, diskSize: UInt64), E>) -> Void

    /// The metadata key used for the used memory.
    var usedMemoryMetadataKey: Metadata.Key { get }

    /// The metadata key used for the used disk.
    var usedDiskMetadataKey: Metadata.Key { get }

    /// The metadata key used for the blob size being read/written.
    var blobSizeMetadataKey: Metadata.Key { get }

    /// The metadata key used for the error.
    var errorMetadataKey: Metadata.Key { get }

    /// The metric identifier for a memory read operation.
    var memoryReadIdentifier: Identifier { get }

    /// The metric identifier for a memory write operation.
    var memoryWriteIdentifier: Identifier { get }

    /// The metric identifier for a disk read operation.
    var diskReadIdentifier: Identifier { get }

    /// The metric identifier for a disk write operation.
    var diskWriteIdentifier: Identifier { get }

    /// Measures a memory read operation's execution time.
    ///
    /// - Parameters:
    ///   - execute: The memory read execution closure.
    ///   - stop: The closure to be invoked by `execute` to stop measuring the execution time, along with the additional
    /// metric metadata.
    ///   - blobSize: The read blob's size in bytes.
    ///   - memorySize: The used memory's size in bytes.
    /// - Returns: The memory read result, if any.
    /// - Throws: The memory read error, if any.
    func measureMemoryRead<T, E>(execute: (_ stop: @escaping MemoryAccessStopClosure<E>) throws -> T) rethrows -> T

    /// Measures a memory write operation's execution time.
    ///
    /// - Parameters:
    ///   - execute: The memory write execution closure.
    ///   - stop: The closure to be invoked by `execute` to stop measuring the execution time, along with the additional
    /// metric metadata.
    ///   - blobSize: The written blob's size in bytes.
    ///   - memorySize: The used memory's size in bytes.
    /// - Returns: The memory write result, if any.
    /// - Throws: The memory write error, if any.
    func measureMemoryWrite<T, E>(execute: (_ stop: @escaping MemoryAccessStopClosure<E>) throws -> T) rethrows -> T

    /// Measures a disk read operation's execution time.
    ///
    /// - Parameters:
    ///   - execute: The disk read execution closure.
    ///   - stop: The closure to be invoked by `execute` to stop measuring the execution time, along with the additional
    /// metric metadata.
    ///   - blobSize: The read blob's size in bytes.
    ///   - diskSize: The used disk's size in bytes.
    /// - Returns: The disk read result, if any.
    /// - Throws: The disk read error, if any.
    func measureDiskRead<T, E>(execute: (_ stop: @escaping DiskAccessStopClosure<E>) throws -> T) rethrows -> T

    /// Measures a disk write operation's execution time.
    ///
    /// - Parameters:
    ///   - execute: The disk write execution closure.
    ///   - stop: The closure to be invoked by `execute` to stop measuring the execution time, along with the additional
    /// metric metadata.
    ///   - blobSize: The written blob's size in bytes.
    ///   - diskSize: The used disk's size in bytes.
    /// - Returns: The memory read result, if any.
    /// - Throws: The memory read error, if any.
    func measureDiskWrite<T, E>(execute: (_ end: @escaping DiskAccessStopClosure<E>) throws -> T) rethrows -> T
}

public extension PersistencePerformanceMetricsTracker {

    // MARK: - Keys and Identifiers

    var usedMemoryMetadataKey: Metadata.Key { return "total_ram" }
    var usedDiskMetadataKey: Metadata.Key { return "total_disk" }
    var blobSizeMetadataKey: Metadata.Key { return "size" }
    var errorMetadataKey: Metadata.Key { return "error" }

    var memoryReadIdentifier: Identifier { return "read_memory" }
    var memoryWriteIdentifier: Identifier { return "write_memory" }
    var diskReadIdentifier: Identifier { return "read_disk" }
    var diskWriteIdentifier: Identifier { return "write_disk" }

    // MARK: - Memory Metrics

    func measureMemoryRead<T, E>(execute: (_ stop: @escaping MemoryAccessStopClosure<E>) throws -> T) rethrows -> T {

        return try measure(with: memoryReadIdentifier) { stopMetadata in

            // the closure is non escaping, so we can safely use `self`
            try execute { result in

                switch result {
                case .success(let blobSize, let memSize):
                    stopMetadata([self.blobSizeMetadataKey : blobSize, self.usedMemoryMetadataKey : memSize])
                case .failure(let error):
                    stopMetadata([self.errorMetadataKey : error])
                }
            }
        }
    }

    func measureMemoryWrite<T, E>(execute: (_ stop: @escaping MemoryAccessStopClosure<E>) throws -> T) rethrows -> T {

        return try measure(with: memoryWriteIdentifier) { stopMetadata in

            // the closure is non escaping, so we can safely use `self`
            try execute { result in

                switch result {
                case .success(let blobSize, let memSize):
                    stopMetadata([self.blobSizeMetadataKey : blobSize, self.usedMemoryMetadataKey : memSize])
                case .failure(let error):
                    stopMetadata([self.errorMetadataKey : error])
                }
            }
        }
    }

    // MARK: - Disk Metrics

    func measureDiskRead<T, E>(execute: (_ stop: @escaping DiskAccessStopClosure<E>) throws -> T) rethrows -> T {

        return try measure(with: diskReadIdentifier) { stopMetadata in

            // the closure is non escaping, so we can safely use `self`
            try execute { result in

                switch result {
                case .success(let blobSize, let diskSize):
                    stopMetadata([self.blobSizeMetadataKey : blobSize, self.usedDiskMetadataKey : diskSize])
                case .failure(let error):
                    stopMetadata([self.errorMetadataKey : error])
                }
            }
        }
    }

    func measureDiskWrite<T, E>(execute: (_ stop: @escaping DiskAccessStopClosure<E>) throws -> T) rethrows -> T {

        return try measure(with: diskWriteIdentifier) { stopMetadata in

            // the closure is non escaping, so we can safely use `self`
            try execute { result in

                switch result {
                case .success(let blobSize, let diskSize):
                    stopMetadata([self.blobSizeMetadataKey : blobSize, self.usedDiskMetadataKey : diskSize])
                case .failure(let error):
                    stopMetadata([self.errorMetadataKey : error])
                }
            }
        }
    }
}


//
//  PersistencePerformanceMetrics.swift
//  Alicerce
//
//  Created by Daniela Dias on 20/02/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import Foundation

public struct PersistencePerformanceMetrics {

    private let metrics: PerformanceMetrics
    private let memoryAttributeKey: String
    private let diskAttributeKey: String
    private let blobSizeAttributeKey: String
    private let readMemoryEventKey: String
    private let writeMemoryEventKey: String
    private let readDiskEventKey: String
    private let writeDiskEventKey: String

    public init(metrics: PerformanceMetrics,
                memoryAttributeKey: String = "total_ram",
                diskAttributeKey: String = "total_disk",
                blobSizeAttributeKey: String = "size",
                readMemoryEventKey: String = "read_memory",
                writeMemoryEventKey: String = "write_memory",
                readDiskEventKey: String = "read_disk",
                writeDiskEventKey: String = "write_disk") {

        self.metrics = metrics
        self.memoryAttributeKey = memoryAttributeKey
        self.diskAttributeKey = diskAttributeKey
        self.blobSizeAttributeKey = blobSizeAttributeKey
        self.readMemoryEventKey = readMemoryEventKey
        self.writeMemoryEventKey = writeMemoryEventKey
        self.readDiskEventKey = readDiskEventKey
        self.writeDiskEventKey = writeDiskEventKey
    }

    // MARK: - Memory Metrics

    public func beginReadMemory() {
        metrics.begin(with: readMemoryEventKey)
    }

    public func endReadMemory() {
        metrics.end(with: readMemoryEventKey)
    }

    public func beginWriteMemory() {
        metrics.begin(with: writeMemoryEventKey)
    }

    public func endWriteMemory(blobSize: UInt64, memorySize: UInt64) {
        metrics.end(with: writeMemoryEventKey, metadata: [blobSizeAttributeKey : blobSize,
                                                          memoryAttributeKey: memorySize])
    }

    // MARK: - Disk Metrics

    public func beginReadDisk() {
        metrics.begin(with: readDiskEventKey)
    }

    public func endReadDisk() {
        metrics.end(with: readDiskEventKey)
    }

    public func beginWriteDisk() {
        metrics.begin(with: writeDiskEventKey)
    }

    public func endWriteDisk(blobSize: UInt64, diskSize: UInt64) {
        metrics.end(with: writeDiskEventKey, metadata: [blobSizeAttributeKey : blobSize,
                                                        diskAttributeKey: diskSize])
    }
}

import XCTest

@testable import Alicerce

final class DiskMemoryPersistenceTestCase: XCTestCase {

    // MARK: Lifecycle

    func testInit_UsingExtraPath_ItShouldCreateADirectory() {
        let _ = diskMemoryPersistence(withDiskLimit: 0, memLimit: 0, extraPath: "Test1")

        let isDir = dirExists("Test1")

        XCTAssertTrue(isDir)
    }

    func testInit_WhenInitialisedWithLimit_ItShouldNotHoldMoreThanThoseFiles() {
        let diskLimit = UInt64(Float(mrMinderSize) * 2.5) // add some "margin" because of filesystem extra bytes
        let writeQueue = DispatchQueue(label: "testInit_WhenInitialisedWithLimit_ItShouldNotHoldMoreThanThoseFiles")
        let persistence = diskMemoryPersistence(withDiskLimit: diskLimit,
                                                memLimit: 1,
                                                extraPath: "Test2",
                                                writeQueue: writeQueue)

        let expectation1 = self.expectation(description: "Save MrMinder1")
        persistMinder(with: "mr-minder", into: persistence, expectation: expectation1)
        let expectation2 = self.expectation(description: "Save MrMinder2")
        persistMinder(with: "mr-minder1", into: persistence, expectation: expectation2)
        let expectation3 = self.expectation(description: "Save MrMinder3")
        persistMinder(with: "mr-minder2", into: persistence, expectation: expectation3)

        waitForExpectations(timeout: 1)

        // wait for all operations (including the eviction ones) to finish
        writeQueue.sync {}

        // should evict mr-minder, since it there's only space for two and it will be the less recently accessed
        XCTAssertFalse(fileExists("Test2/mr-minder"))
        XCTAssertTrue(fileExists("Test2/mr-minder1"))
        XCTAssertTrue(fileExists("Test2/mr-minder2"))
    }

    // MARK: Without performance metrics

    // setObject

    func testSetObject_WhenAnObjectIsCached_ItShouldStoreTheObjectInDisk() {
        let sizeLimit = UInt64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let writeQueue =
            DispatchQueue(label: "testSetObject_WhenAnObjectIsCached_ItShouldStoreTheObjectInDisk")
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: "Test3",
                                                writeQueue: writeQueue)

        let expectation = self.expectation(description: "Save MrMinder into disk")
        persistence.setObject(mrMinderData, for: "👾") {
            $0.analysis(ifSuccess: {}, ifFailure: { XCTFail("💥 failed to save image with error: \($0)") })
            
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        // wait for all operations (including the eviction ones) to finish
        writeQueue.sync {}

        XCTAssertTrue(fileExists("Test3/👾"))
    }

    func testSetObject_WhenAnObjectIsAlreadyCachedwithSameKey_ItShouldOverwriteTheObjectInDisk() {
        let sizeLimit = UInt64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let writeQueue =
            DispatchQueue(label: "testSetObject_WhenAnObjectIsAlreadyCachedwithSameKey_ItShouldOverwriteTheObjectInDisk")
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: "Test3",
                                                writeQueue: writeQueue)

        let firstWrite = self.expectation(description: "Save MrMinder into disk first time")
        persistence.setObject(mrMinderData, for: "👾") {
            $0.analysis(ifSuccess: {}, ifFailure: { XCTFail("💥 failed to save image with error: \($0)") })

            firstWrite.fulfill()
        }

        waitForExpectations(timeout: 1)

        // wait for all operations (including the eviction ones) to finish
        writeQueue.sync {}

        XCTAssertTrue(fileExists("Test3/👾"))

        let secondWrite = self.expectation(description: "Save MrMinder into disk second time")
        persistence.setObject(mrMinderData, for: "👾") {
            $0.analysis(ifSuccess: {}, ifFailure: { XCTFail("💥 failed to save image with error: \($0)") })

            secondWrite.fulfill()
        }

        waitForExpectations(timeout: 1)

        // wait for all operations (including the eviction ones) to finish
        writeQueue.sync {}

        XCTAssertTrue(fileExists("Test3/👾"))
    }

    // removeObject

    func testRemoveObject_WhenACachedObjectIsRemoved_ItShouldRemoveTheObjectFromTheDisk() {
        let sizeLimit = UInt64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let writeQueue =
            DispatchQueue(label: "testRemoveObject_WhenACachedObjectIsRemoved_ItShouldRemoveTheObjectFromTheDisk")
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: "Test4",
                                                writeQueue: writeQueue)

        let saveExpectation = self.expectation(description: "Save MrMinder into disk")
        persistence.setObject(mrMinderData, for: "🚀") {
            $0.analysis(ifSuccess: {}, ifFailure: { XCTFail("💥 failed to save image with error: \($0)") })
            
            saveExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        // wait for all operations (including the eviction ones) to finish
        writeQueue.sync {}

        let removeExpectation = self.expectation(description: "Remove MrMinder from disk")
        persistence.removeObject(for: "🚀") {
            $0.analysis(ifSuccess: {}, ifFailure: { XCTFail("💥 Failed to remove object with error: \($0)") })

            removeExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        // wait for all operations (including the eviction ones) to finish
        writeQueue.sync {}

        XCTAssertFalse(fileExists("Test4/🚀"))
    }

    // object

    func testObject_WhenAnObjectIsNotInMemoryButInDisk_ItShouldLoadTheObjectFromDisk() {
        let sizeLimit = UInt64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        var persistence = diskMemoryPersistence(withDiskLimit: sizeLimit, memLimit: sizeLimit, extraPath: "Test5")
        
        let saveExpectation = self.expectation(description: "Save MrMinder")
        persistence.setObject(mrMinderData, for: "🎃") {
            $0.analysis(ifSuccess: {}, ifFailure: { XCTFail("💥 failed to save image with error: \($0)") })

            saveExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        let readExpectation = self.expectation(description: "Read MrMinder")

        // recreate persistence so memory cache is empty
        persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                            memLimit: sizeLimit,
                                            extraPath: "Test5",
                                            removeDir: false)

        persistence.object(for: "🎃") {
            $0.analysis(ifSuccess: { XCTAssertEqual($0, mrMinderData) },
                        ifFailure: { XCTFail("💥 failed to get object from disk with error: \($0)") })

            readExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testObject_WhenWeTryToGetAnInexistingObject_ItShouldReturnNil() {
        let sizeLimit = UInt64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit, memLimit: sizeLimit, extraPath: "Test6")

        let expectation = self.expectation(description: "Cache miss")
        persistence.object(for: "🚫") {
            switch $0 {
            case .success(nil): break // 🤠 well done
            case .success(let value?): XCTFail("💥 found object \(value) for key '🚫' 😳")
            case .failure(let error): XCTFail("💥 failed to get object from disk with error: \(error)")
            }
            
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    // MARK: With performance metrics

    // setObject

    func testSetObject_WhenAnObjectIsCachedWithPerformanceMetrics_ItShouldStoreTheObjectInDisk() {
        let performanceMetrics = MockPersistencePerformanceMetricsTracker()
        let sizeLimit = UInt64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let writeQueue =
            DispatchQueue(label: "testSetObject_WhenAnObjectIsCachedWithPerformanceMetrics_ItShouldStoreTheObjectInDisk")
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: "Test7",
                                                performanceMetrics:  performanceMetrics,
                                                writeQueue: writeQueue)

        let measure = self.expectation(description: "measure")
        measure.expectedFulfillmentCount = 2

        performanceMetrics.measureInvokedClosure = { [count = VarBox(0)] identifier, metadata in
            if count.value == 0 {
                XCTAssertEqual(identifier, performanceMetrics.memoryWriteIdentifier)
                XCTAssertDumpsEqual(metadata, [performanceMetrics.blobSizeMetadataKey : mrMinderSize,
                                               performanceMetrics.usedMemoryMetadataKey : mrMinderSize])
            } else {
                XCTAssertEqual(identifier, performanceMetrics.diskWriteIdentifier)
                XCTAssertDumpsEqual(metadata, [performanceMetrics.blobSizeMetadataKey : mrMinderSize,
                                               performanceMetrics.usedDiskMetadataKey : mrMinderSize])
            }
            count.value += 1
            measure.fulfill()
        }

        let expectation = self.expectation(description: "Save MrMinder into disk")
        persistence.setObject(mrMinderData, for: "👾") {
            $0.analysis(ifSuccess: {}, ifFailure: { XCTFail("💥 failed to save image with error: \($0)") })

            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        // wait for all operations (including the eviction ones) to finish
        writeQueue.sync {}

        XCTAssertTrue(fileExists("Test3/👾"))
    }

    // removeObject

    func testRemoveObject_WhenACachedObjectIsRemovedWithPerformanceMetrics_ItShouldRemoveTheObjectFromTheDisk() {
        let performanceMetrics = MockPersistencePerformanceMetricsTracker()
        let sizeLimit = UInt64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let writeQueue =
            DispatchQueue(label: "testRemoveObject_WhenACachedObjectIsRemovedWithPerformanceMetrics_ItShouldRemoveTheObjectFromTheDisk")
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: "Test8",
                                                performanceMetrics: performanceMetrics,
                                                writeQueue: writeQueue)

        let measure = self.expectation(description: "measure")
        measure.expectedFulfillmentCount = 2

        performanceMetrics.measureInvokedClosure = { [count = VarBox(0)] identifier, metadata in
            if count.value == 0 {
                XCTAssertEqual(identifier, performanceMetrics.memoryWriteIdentifier)
                XCTAssertDumpsEqual(metadata, [performanceMetrics.blobSizeMetadataKey : mrMinderSize,
                                               performanceMetrics.usedMemoryMetadataKey : mrMinderSize])
            } else {
                XCTAssertEqual(identifier, performanceMetrics.diskWriteIdentifier)
                XCTAssertDumpsEqual(metadata, [performanceMetrics.blobSizeMetadataKey : mrMinderSize,
                                               performanceMetrics.usedDiskMetadataKey : mrMinderSize])
            }
            count.value += 1
            measure.fulfill()
        }

        let saveExpectation = self.expectation(description: "Save MrMinder into disk")
        persistence.setObject(mrMinderData, for: "🚀") {
            $0.analysis(ifSuccess: {}, ifFailure: { XCTFail("💥 failed to save image with error: \($0)") })

            saveExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        // wait for all operations (including the eviction ones) to finish
        writeQueue.sync {}

        let removeExpectation = self.expectation(description: "Remove MrMinder from disk")
        persistence.removeObject(for: "🚀") {
            $0.analysis(ifSuccess: {}, ifFailure: { XCTFail("💥 failed to remove object with error: \($0)") })

            removeExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        // wait for all operations (including the eviction ones) to finish
        writeQueue.sync {}

        XCTAssertFalse(fileExists("Test4/🚀"))
    }

    // object

    func testObject_WhenAnObjectIsNotInMemoryButInDiskWithPerformanceMetrics_ItShouldLoadTheObjectFromDisk() {
        let performanceMetrics = MockPersistencePerformanceMetricsTracker()
        let sizeLimit = UInt64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let writeQueue =
            DispatchQueue(label: "testObject_WhenAnObjectIsNotInMemoryButInDiskWithPerformanceMetrics_ItShouldLoadTheObjectFromDisk")
        var persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: "Test9",
                                                performanceMetrics: performanceMetrics,
                                                writeQueue: writeQueue)

        let measure = self.expectation(description: "measure")
        measure.expectedFulfillmentCount = 2

        performanceMetrics.measureInvokedClosure = { [count = VarBox(0)] identifier, metadata in
            if count.value == 0 {
                XCTAssertEqual(identifier, performanceMetrics.memoryWriteIdentifier)
                XCTAssertDumpsEqual(metadata, [performanceMetrics.blobSizeMetadataKey : mrMinderSize,
                                               performanceMetrics.usedMemoryMetadataKey : mrMinderSize])
            } else {
                XCTAssertEqual(identifier, performanceMetrics.diskWriteIdentifier)
                XCTAssertDumpsEqual(metadata, [performanceMetrics.blobSizeMetadataKey : mrMinderSize,
                                               performanceMetrics.usedDiskMetadataKey : mrMinderSize])
            }
            count.value += 1
            measure.fulfill()
        }

        let saveExpectation = self.expectation(description: "Save MrMinder")
        persistence.setObject(mrMinderData, for: "🎃") {
            $0.analysis(ifSuccess: {},
                        ifFailure: { XCTFail("💥 failed to save image with error: \($0)") })

            saveExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        // wait for all operations (including the eviction ones) to finish
        writeQueue.sync {}

        let readExpectation = self.expectation(description: "Read MrMinder")

        // recreate persistence so memory cache is empty
        persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                            memLimit: sizeLimit,
                                            extraPath: "Test9",
                                            performanceMetrics:  performanceMetrics,
                                            writeQueue: writeQueue,
                                            removeDir: false)

        let measure2 = self.expectation(description: "measure")
        measure2.expectedFulfillmentCount = 3

        performanceMetrics.measureInvokedClosure = { [count = VarBox(0)] identifier, metadata in
            if count.value == 0 {
                XCTAssertEqual(identifier, performanceMetrics.memoryReadIdentifier)
                // cache miss
                XCTAssertDumpsEqual(metadata, [performanceMetrics.blobSizeMetadataKey : 0,
                                               performanceMetrics.usedMemoryMetadataKey : 0])
            } else if count.value == 1 {
                XCTAssertEqual(identifier, performanceMetrics.diskReadIdentifier)
                XCTAssertDumpsEqual(metadata, [performanceMetrics.blobSizeMetadataKey : mrMinderSize,
                                               performanceMetrics.usedDiskMetadataKey : mrMinderSize])
            } else {
                XCTAssertEqual(identifier, performanceMetrics.memoryWriteIdentifier)
                XCTAssertDumpsEqual(metadata, [performanceMetrics.blobSizeMetadataKey : mrMinderSize,
                                               performanceMetrics.usedMemoryMetadataKey : mrMinderSize])
            }
            count.value += 1
            measure2.fulfill()
        }

        persistence.object(for: "🎃") {
            $0.analysis(ifSuccess: { XCTAssertEqual($0, mrMinderData) },
                        ifFailure: { XCTFail("💥 failed to get object from disk with error: \($0)") })

            readExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testObject_WhenWeTryToGetAnInexistingObjectWithPerformanceMetrics_ItShouldReturnZeroBlobSize() {
        let performanceMetrics = MockPersistencePerformanceMetricsTracker()
        let sizeLimit = UInt64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: "Test10",
                                                performanceMetrics:  performanceMetrics)

        let measure = self.expectation(description: "measure")
        measure.expectedFulfillmentCount = 2

        performanceMetrics.measureInvokedClosure = { [count = VarBox(0)] identifier, metadata in
            if count.value == 0 {
                XCTAssertEqual(identifier, performanceMetrics.memoryReadIdentifier)
                XCTAssertDumpsEqual(metadata, [performanceMetrics.blobSizeMetadataKey : 0,
                                               performanceMetrics.usedMemoryMetadataKey : 0])
            } else {
                XCTAssertEqual(identifier, performanceMetrics.diskReadIdentifier)
                XCTAssertDumpsEqual(metadata, [performanceMetrics.blobSizeMetadataKey : 0,
                                               performanceMetrics.usedDiskMetadataKey : 0])
            }

            count.value += 1
            measure.fulfill()
        }

        let expectation = self.expectation(description: "Cache miss")
        persistence.object(for: "🚫") {
            switch $0 {
            case .success(nil): break // 🤠 well done
            case .success(let value?): XCTFail("💥 found object \(value) for key '🚫' 😳")
            case .failure(let error): XCTFail("💥 failed to get object from disk with error: \(error)")
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }
}

// MARK: - Helpers

fileprivate let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
fileprivate let testPath = cachePath + "/test"

fileprivate let mrMinder = imageFromFile(withName: "mr-minder", type: "png")

fileprivate func diskMemoryPersistence(withDiskLimit diskLimit: UInt64,
                                       memLimit: UInt64,
                                       extraPath: String = "test",
                                       performanceMetrics: PersistencePerformanceMetricsTracker? = nil,
                                       readQueue: DispatchQueue? = nil,
                                       writeQueue: DispatchQueue =
                                        DispatchQueue(label: "com.mindera.alicerce.diskMemoryPersistence.writeQueue"),
                                       removeDir: Bool = true) -> Persistence.DiskMemoryPersistenceStack {

    let testPath = cachePath + "/" + extraPath

    if removeDir {
        try? FileManager.default.removeItem(atPath: testPath)
    }

    let configuration = Persistence.DiskMemoryPersistenceStack.Configuration(diskLimit: diskLimit,
                                                                             memLimit: memLimit,
                                                                             path: testPath,
                                                                             performanceMetrics: performanceMetrics,
                                                                             readQueue: readQueue,
                                                                             writeQueue: writeQueue)

    return try! Persistence.DiskMemoryPersistenceStack(configuration: configuration)
}

fileprivate var mrMinderData: Data = {
    guard let data = UIImagePNGRepresentation(mrMinder) else {
        assertionFailure("💥 could not convert image into data 😱")

        return Data()
    }

    return data
}()

fileprivate var mrMinderSize: UInt64 = UInt64((mrMinderData as NSData).length)

fileprivate func fileExists(_ path: String) -> Bool {
    let finalPath = cachePath + "/" + path
    return FileManager.default.fileExists(atPath: finalPath)
}

fileprivate func dirExists(_ path: String) -> Bool {
    let finalPath = cachePath + "/" + path
    var isDir = ObjCBool(false)
    return FileManager.default.fileExists(atPath: finalPath, isDirectory: &isDir) && isDir.boolValue
}

fileprivate func deleteItem(_ item: String) {
    let finalPath = cachePath + "/" + item
    do {
        try FileManager.default.removeItem(atPath: finalPath)
    } catch {
        print("⚠️ Failed to remove file with error 👉 \(error)")
    }
}

func persistMinder(with key: Persistence.Key,
                   into persistenceStack: Persistence.DiskMemoryPersistenceStack,
                   expectation: XCTestExpectation) {

    persistenceStack.setObject(mrMinderData, for: key) { result in
        switch result {
        case .success: break
        case .failure(let error): XCTFail("💥 failed to save image with error \(error)")
        }
        
        expectation.fulfill()
    }

}

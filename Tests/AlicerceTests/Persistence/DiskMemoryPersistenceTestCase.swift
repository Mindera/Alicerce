import XCTest

@testable import Alicerce

final class DiskMemoryPersistenceTestCase: XCTestCase {

    // MARK: Lifecycle

    func testInit_UsingExtraPath_ItShouldCreateADirectory() {
        let testName = "testInit_UsingExtraPath_ItShouldCreateADirectory"
        let _ = diskMemoryPersistence(withDiskLimit: 0, memLimit: 0, extraPath: testName)

        let isDir = dirExists(testName)

        XCTAssertTrue(isDir)
    }

    func testInit_WhenInitialisedWithLimit_ItShouldNotHoldMoreThanThoseFiles() {
        let testName = "testInit_WhenInitialisedWithLimit_ItShouldNotHoldMoreThanThoseFiles"
        let diskLimit = Int64(Float(mrMinderSize) * 2.5) // add some "margin" because of filesystem extra bytes
        let writeQueue = DispatchQueue(label: testName)
        let persistence = diskMemoryPersistence(withDiskLimit: diskLimit,
                                                memLimit: 1,
                                                extraPath: testName,
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
        XCTAssertFalse(fileExists("\(testName)/mr-minder"))
        XCTAssertTrue(fileExists("\(testName)/mr-minder1"))
        XCTAssertTrue(fileExists("\(testName)/mr-minder2"))
    }

    // MARK: Without performance metrics

    // setObject

    func testSetObject_WhenAnObjectIsCached_ItShouldStoreTheObjectInDisk() {
        let testName = "testSetObject_WhenAnObjectIsCached_ItShouldStoreTheObjectInDisk"
        let sizeLimit = Int64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: testName)

        let writeExpectation = expectation(description: "Save MrMinder into disk")
        persistence.setObject(mrMinderData, for: "👾") {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                return XCTFail("🔥 Unexpected error: \(error)!")
            }
            
            writeExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(fileExists("\(testName)/👾"))
    }

    func testSetObject_WhenAnObjectIsAlreadyCachedwithSameKey_ItShouldOverwriteTheObjectInDisk() {
        let testName = "testSetObject_WhenAnObjectIsAlreadyCachedwithSameKey_ItShouldOverwriteTheObjectInDisk"
        let sizeLimit = Int64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: testName)

        let firstWrite = self.expectation(description: "Save MrMinder into disk first time")
        persistence.setObject(mrMinderData, for: "👾") {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                return XCTFail("🔥 Unexpected error: \(error)!")
            }

            firstWrite.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(fileExists("\(testName)/👾"))

        let secondWrite = self.expectation(description: "Save MrMinder into disk second time")
        persistence.setObject(mrMinderData, for: "👾") {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                return XCTFail("🔥 Unexpected error: \(error)!")
            }

            secondWrite.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(fileExists("\(testName)/👾"))
    }

    // removeObject

    func testRemoveObject_WhenACachedObjectIsRemoved_ItShouldRemoveTheObjectFromTheDisk() {
        let testName = "testRemoveObject_WhenACachedObjectIsRemoved_ItShouldRemoveTheObjectFromTheDisk"
        let sizeLimit = Int64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: testName)

        let saveExpectation = expectation(description: "Save MrMinder into disk")
        persistence.setObject(mrMinderData, for: "🚀") {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                return XCTFail("🔥 Unexpected error: \(error)!")
            }
            
            saveExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        let removeExpectation = expectation(description: "Remove MrMinder from disk")
        persistence.removeObject(for: "🚀") {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                return XCTFail("🔥 Unexpected error: \(error)!")
            }

            removeExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertFalse(fileExists("\(testName)/🚀"))
    }

    // object

    func testObject_WhenAnObjectIsInMemory_ItShouldLoadTheObjectFromMemory() {
        let testName = "testObject_WhenAnObjectIsInMemory_ItShouldLoadTheObjectFromMemory"
        let persistence = diskMemoryPersistence(withDiskLimit: 0,
                                                memLimit: mrMinderSize,
                                                extraPath: testName)

        let saveExpectation = expectation(description: "Save MrMinder")
        persistence.setObject(mrMinderData, for: "🎃") {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                return XCTFail("🔥 Unexpected error: \(error)!")
            }

            saveExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        let readExpectation = expectation(description: "Read MrMinder")

        persistence.object(for: "🎃") {
            switch $0 {
            case .success(let value):
                XCTAssertEqual(value, mrMinderData)
            case .failure(let error):
                return XCTFail("🔥 Unexpected error: \(error)!")
            }

            readExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testObject_WhenAnObjectIsNotInMemoryButInDisk_ItShouldLoadTheObjectFromDisk() {
        let testName = "testObject_WhenAnObjectIsNotInMemoryButInDisk_ItShouldLoadTheObjectFromDisk"
        let sizeLimit = Int64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        var persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: testName)
        
        let saveExpectation = expectation(description: "Save MrMinder")
        persistence.setObject(mrMinderData, for: "🎃") {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                return XCTFail("🔥 Unexpected error: \(error)!")
            }

            saveExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        let readExpectation = expectation(description: "Read MrMinder")

        // recreate persistence so memory cache is empty
        persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                            memLimit: sizeLimit,
                                            extraPath: testName,
                                            removeDir: false)

        persistence.object(for: "🎃") {
            switch $0 {
            case .success(let value):
                XCTAssertEqual(value, mrMinderData)
            case .failure(let error):
                return XCTFail("🔥 Unexpected error: \(error)!")
            }

            readExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testObject_WhenWeTryToGetAnInexistingObject_ItShouldReturnNil() {
        let testName = "testObject_WhenAnObjectIsNotInMemoryButInDisk_ItShouldLoadTheObjectFromDisk"
        let sizeLimit = Int64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit, memLimit: sizeLimit, extraPath: testName)

        let readExpectation = expectation(description: "Cache miss")
        persistence.object(for: "🚫") {
            switch $0 {
            case .success(nil): break // 🤠 well done
            case .success(let value?): XCTFail("💥 found object \(value) for key '🚫' 😳")
            case .failure(let error): XCTFail("💥 failed to get object from disk with error: \(error)")
            }
            
            readExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    // MARK: With performance metrics

    // setObject

    func testSetObject_WhenAnObjectIsCachedWithPerformanceMetrics_ItShouldStoreTheObjectInDisk() {
        let testName = "testSetObject_WhenAnObjectIsCachedWithPerformanceMetrics_ItShouldStoreTheObjectInDisk"
        let performanceMetrics = MockPersistencePerformanceMetricsTracker()
        let sizeLimit = Int64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: testName,
                                                performanceMetrics: performanceMetrics)

        let measureExpectation = expectation(description: "measure")
        measureExpectation.expectedFulfillmentCount = 2

        performanceMetrics.measureInvokedClosure = { [count = Box(0)] identifier, metadata in
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
            measureExpectation.fulfill()
        }

        let writeExpectation = expectation(description: "Save MrMinder into disk")
        persistence.setObject(mrMinderData, for: "👾") {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                return XCTFail("🔥 Unexpected error: \(error)!")
            }

            writeExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(fileExists("\(testName)/👾"))
    }

    // removeObject

    func testRemoveObject_WhenACachedObjectIsRemovedWithPerformanceMetrics_ItShouldRemoveTheObjectFromTheDisk() {
        let testName = "testRemoveObject_WhenACachedObjectIsRemovedWithPerformanceMetrics_ItShouldRemoveTheObjectFromTheDisk"
        let performanceMetrics = MockPersistencePerformanceMetricsTracker()
        let sizeLimit = Int64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let writeQueue = DispatchQueue(label: testName)
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: testName,
                                                performanceMetrics: performanceMetrics,
                                                writeQueue: writeQueue)

        let measure = self.expectation(description: "measure")
        measure.expectedFulfillmentCount = 2

        performanceMetrics.measureInvokedClosure = { [count = Box(0)] identifier, metadata in
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

        let saveExpectation = expectation(description: "Save MrMinder into disk")
        persistence.setObject(mrMinderData, for: "🚀") {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                return XCTFail("🔥 Unexpected error: \(error)!")
            }

            saveExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        let removeExpectation = expectation(description: "Remove MrMinder from disk")
        persistence.removeObject(for: "🚀") {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                return XCTFail("🔥 Unexpected error: \(error)!")
            }

            removeExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertFalse(fileExists("\(testName)/🚀"))
    }

    // object

    func testObject_WhenAnObjectIsInMemoryWithPerformanceMetrics_ItShouldLoadTheObjectFromMemory() {
        let testName = "testObject_WhenAnObjectIsInMemoryWithPerformanceMetrics_ItShouldLoadTheObjectFromMemory"
        let performanceMetrics = MockPersistencePerformanceMetricsTracker()
        let persistence = diskMemoryPersistence(withDiskLimit: 0,
                                                memLimit: mrMinderSize,
                                                extraPath: testName,
                                                performanceMetrics: performanceMetrics)

        let measureExpectation = expectation(description: "measure")
        measureExpectation.expectedFulfillmentCount = 2

        performanceMetrics.measureInvokedClosure = { [count = Box(0)] identifier, metadata in
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
            measureExpectation.fulfill()
        }

        let saveExpectation = expectation(description: "Save MrMinder")
        persistence.setObject(mrMinderData, for: "🎃") {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                return XCTFail("🔥 Unexpected error: \(error)!")
            }

            saveExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        let readExpectation = expectation(description: "Read MrMinder")

        let measureExpectation2 = expectation(description: "measure")

        performanceMetrics.measureInvokedClosure = { identifier, metadata in
            XCTAssertEqual(identifier, performanceMetrics.memoryReadIdentifier)
            XCTAssertDumpsEqual(metadata, [performanceMetrics.blobSizeMetadataKey : mrMinderSize,
                                           performanceMetrics.usedMemoryMetadataKey : mrMinderSize])

            measureExpectation2.fulfill()
        }

        persistence.object(for: "🎃") {
            switch $0 {
            case .success(let value):
                XCTAssertEqual(value, mrMinderData)
            case .failure(let error):
                return XCTFail("🔥 Unexpected error: \(error)!")
            }

            readExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testObject_WhenAnObjectIsNotInMemoryButInDiskWithPerformanceMetrics_ItShouldLoadTheObjectFromDisk() {
        let testName = "testObject_WhenAnObjectIsNotInMemoryButInDiskWithPerformanceMetrics_ItShouldLoadTheObjectFromDisk"
        let performanceMetrics = MockPersistencePerformanceMetricsTracker()
        let sizeLimit = Int64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        var persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: testName,
                                                performanceMetrics: performanceMetrics)

        let measureExpectation = expectation(description: "measure")
        measureExpectation.expectedFulfillmentCount = 2

        performanceMetrics.measureInvokedClosure = { [count = Box(0)] identifier, metadata in
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
            measureExpectation.fulfill()
        }

        let saveExpectation = expectation(description: "Save MrMinder")
        persistence.setObject(mrMinderData, for: "🎃") {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                return XCTFail("🔥 Unexpected error: \(error)!")
            }

            saveExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        let readExpectation = expectation(description: "Read MrMinder")

        // recreate persistence so memory cache is empty
        persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                            memLimit: sizeLimit,
                                            extraPath: testName,
                                            performanceMetrics: performanceMetrics,
                                            removeDir: false)

        let measureExpectation2 = expectation(description: "measure")
        measureExpectation2.expectedFulfillmentCount = 3

        performanceMetrics.measureInvokedClosure = { [count = Box(0)] identifier, metadata in
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
            measureExpectation2.fulfill()
        }

        persistence.object(for: "🎃") {
            switch $0 {
            case .success(let value):
                XCTAssertEqual(value, mrMinderData)
            case .failure(let error):
                return XCTFail("🔥 Unexpected error: \(error)!")
            }

            readExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testObject_WhenWeTryToGetAnInexistingObjectWithPerformanceMetrics_ItShouldReturnZeroBlobSize() {
        let testName = "testObject_WhenWeTryToGetAnInexistingObjectWithPerformanceMetrics_ItShouldReturnZeroBlobSize"
        let performanceMetrics = MockPersistencePerformanceMetricsTracker()
        let sizeLimit = Int64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: testName,
                                                performanceMetrics: performanceMetrics)

        let measureExpectation = expectation(description: "measure")
        measureExpectation.expectedFulfillmentCount = 2

        performanceMetrics.measureInvokedClosure = { [count = Box(0)] identifier, metadata in
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
            measureExpectation.fulfill()
        }

        let readExpectation = expectation(description: "Cache miss")
        persistence.object(for: "🚫") {
            switch $0 {
            case .success(nil): break // 🤠 well done
            case .success(let value?): XCTFail("💥 found object \(value) for key '🚫' 😳")
            case .failure(let error): XCTFail("💥 failed to get object from disk with error: \(error)")
            }

            readExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    // MARK: Remove all

    func testRemoveAll_WhenEmpty_ShouldSucceed() {
        let testName = "testRemoveAll_WhenEmpty_ShouldSucceed"
        let sizeLimit = Int64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: testName,
                                                performanceMetrics: nil)

        let removeAllExpectation = expectation(description: "remove all")

        persistence.removeAll {
            switch $0 {
            case .success: break
            case .failure(let error): XCTFail("💥 failed to remove all with error: \(error)")
            }

            removeAllExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testRemoveAll_WhenNotEmpty_ShouldSucceed() {
        let testName = "testRemoveAll_WhenNotEmpty_ShouldSucceed"
        let sizeLimit = Int64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: testName)

        let setExpectation = self.expectation(description: "remove all")

        persistence.setObject(mrMinderData, for: "👾") {
            switch $0 {
            case .success:
                break
            case .failure(let error):
                return XCTFail("🔥 Unexpected error: \(error)!")
            }
            
            setExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(fileExists("\(testName)/👾"))

        let removeAllExpectation = expectation(description: "remove all")

        persistence.removeAll {
            switch $0 {
            case .success: break
            case .failure(let error): XCTFail("💥 failed to remove all with error: \(error)")
            }

            removeAllExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertFalse(fileExists("\(testName)/👾"))
    }
}

// MARK: - Helpers

fileprivate let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
fileprivate let testPath = cachePath + "/test"

fileprivate let mrMinder = imageFromFile(withName: "mr-minder", type: "png")

fileprivate func diskMemoryPersistence(withDiskLimit diskLimit: Int64,
                                       memLimit: Int64,
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
    guard let data = mrMinder.pngData() else {
        assertionFailure("💥 Could not convert image into data 😱")

        return Data()
    }

    return data
}()

fileprivate var mrMinderSize: Int64 = Int64((mrMinderData as NSData).length)

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
        XCTFail("Failed to remove file with error: \(error)")
    }
}

func persistMinder(
    with key: Persistence.DiskMemoryPersistenceStack.Key,
    into persistenceStack: Persistence.DiskMemoryPersistenceStack,
    expectation: XCTestExpectation
) {

    persistenceStack.setObject(mrMinderData, for: key) { result in
        switch result {
        case .success: break
        case .failure(let error): XCTFail("💥 failed to save image with error \(error)")
        }
        
        expectation.fulfill()
    }

}

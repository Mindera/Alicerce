import XCTest

@testable import Alicerce

final class DiskMemoryPersistenceTestCase: XCTestCase {

    func testInit_UsingExtraPath_ItShouldCreateADirectory() {
        let _ = diskMemoryPersistence(withDiskLimit: 0, memLimit: 0, extraPath: "Test1")

        let isDir = dirExists("Test1")

        XCTAssertTrue(isDir)
    }

    func testInit_WhenInitialisedWithLimit_ItShouldNotHoldMoreThanThoseFiles() {
        let diskLimit = UInt64(Float(mrMinderSize) * 2.5) // add some "margin" because of filesystem extra bytes
        let persistence = diskMemoryPersistence(withDiskLimit: diskLimit, memLimit: 1, extraPath: "Test2")

        let expectation1 = self.expectation(description: "Save MrMinder1")
        persistMinder(with: "mr-minder", into: persistence, expectation: expectation1)
        let expectation2 = self.expectation(description: "Save MrMinder2")
        persistMinder(with: "mr-minder1", into: persistence, expectation: expectation2)
        let expectation3 = self.expectation(description: "Save MrMinder3")
        persistMinder(with: "mr-minder2", into: persistence, expectation: expectation3)

        waitForExpectations(timeout: 1)

        // wait for all operations (including the eviction ones) to finish
        persistence.writeOperationQueue.waitUntilAllOperationsAreFinished()

        // should evict mr-minder, since it there's only space for two and it will be the less recently accessed
        XCTAssertFalse(fileExists("Test2/mr-minder"))
        XCTAssertTrue(fileExists("Test2/mr-minder1"))
        XCTAssertTrue(fileExists("Test2/mr-minder2"))
    }

    // no performance metrics

    func testCache_WhenAnObjectIsCached_ItShouldStoreTheObjectInDisk() {
        let sizeLimit = UInt64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit, memLimit: sizeLimit, extraPath: "Test3")

        let expectation = self.expectation(description: "Save MrMinder into disk")
        persistence.setObject(mrMinderData, for: "👾") { (inner: () throws -> ()) in
            do {
                let _ = try inner()
            } catch {
                XCTFail("💥 failed to save image with error \(error)")
            }
            
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(fileExists("Test3/👾"))
    }

    func testCache_WhenACachedObjectIsRemoved_ItShouldRemoveTheObjectFromTheDisk() {
        let sizeLimit = UInt64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit, memLimit: sizeLimit, extraPath: "Test4")

        let saveExpectation = self.expectation(description: "Save MrMinder into disk")
        persistence.setObject(mrMinderData, for: "🚀") { (inner: () throws -> ()) in
            do {
                try inner()
            } catch {
                XCTFail("💥 failed to save image with error \(error)")
            }
            
            saveExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        let removeExpectation = self.expectation(description: "Remove MrMinder from disk")
        persistence.removeObject(for: "🚀") { (inner: () throws -> ()) in
            do {
                try inner()
            } catch {
                XCTFail("💥 while removing object. Error: `\(error)`")
            }

            removeExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertFalse(fileExists("Test4/🚀"))
    }

    func testRestoreFromDisk_WhenAnObjectIsNotInMemoryButInDisk_ItShouldLoadTheObjectFromDisk() {
        let sizeLimit = UInt64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        var persistence = diskMemoryPersistence(withDiskLimit: sizeLimit, memLimit: sizeLimit, extraPath: "Test5")
        
        let saveExpectation = self.expectation(description: "Save MrMinder")
        persistence.setObject(mrMinderData, for: "🎃") { (inner: () throws -> ()) in
            do {
                try inner()
            } catch {
                XCTFail("💥 failed to save image with error \(error)")
            }
            
            saveExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        let readExpectation = self.expectation(description: "Read MrMinder")

        // recreate persistence so memory cache is empty
        persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                            memLimit: sizeLimit,
                                            extraPath: "Test5",
                                            removeDir: false)

        persistence.object(for: "🎃") { (inner: () throws -> Data) in
            do {
                let imageData = try inner()

                XCTAssertEqual(imageData, mrMinderData)
            } catch {
                XCTFail("💥 trying to get object from disk. Error: \(error)")
            }

            readExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testNoObjectError_WhenWeTryToGetAnInexistingObject_ItShouldReturnNoObjectForKey() {
        let sizeLimit = UInt64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit, memLimit: sizeLimit, extraPath: "Test6")

        let expectation = self.expectation(description: "No object for key")
        persistence.object(for: "🚫") { (inner: () throws -> Data) in
            do {
                let _ = try inner()

                XCTFail("💥 found object for key 🚫 😳")
            } catch Persistence.Error.noObjectForKey {
                // 🤠 well done
            }
            catch {
                XCTFail("💥 should return `noObjectForKey` error but got error \(error)")
            }
            
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    // with performance metrics

    func testCache_WhenAnObjectIsCachedWithPerformanceMetrics_ItShouldStoreTheObjectInDisk() {
        let performanceMetrics = MockPersistencePerformanceMetricsTracker()
        let sizeLimit = UInt64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: "Test7",
                                                performanceMetrics:  performanceMetrics)

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
        persistence.setObject(mrMinderData, for: "👾") { (inner: () throws -> ()) in
            do {
                let _ = try inner()
            } catch {
                XCTFail("💥 failed to save image with error \(error)")
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(fileExists("Test3/👾"))
    }

    func testCache_WhenACachedObjectIsRemovedWithPerformanceMetrics_ItShouldRemoveTheObjectFromTheDisk() {
        let performanceMetrics = MockPersistencePerformanceMetricsTracker()
        let sizeLimit = UInt64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        let persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: "Test8",
                                                performanceMetrics:  performanceMetrics)

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
        persistence.setObject(mrMinderData, for: "🚀") { (inner: () throws -> ()) in
            do {
                try inner()
            } catch {
                XCTFail("💥 failed to save image with error \(error)")
            }

            saveExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        let removeExpectation = self.expectation(description: "Remove MrMinder from disk")
        persistence.removeObject(for: "🚀") { (inner: () throws -> ()) in
            do {
                try inner()
            } catch {
                XCTFail("💥 while removing object. Error: `\(error)`")
            }

            removeExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertFalse(fileExists("Test4/🚀"))
    }

    func testRestoreFromDisk_WhenAnObjectIsNotInMemoryButInDiskWithPerformanceMetrics_ItShouldLoadTheObjectFromDisk() {
        let performanceMetrics = MockPersistencePerformanceMetricsTracker()
        let sizeLimit = UInt64(Float(mrMinderSize) * 1.5) // add some "margin" because of filesystem extra bytes
        var persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                                memLimit: sizeLimit,
                                                extraPath: "Test9",
                                                performanceMetrics:  performanceMetrics)

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
        persistence.setObject(mrMinderData, for: "🎃") { (inner: () throws -> ()) in
            do {
                try inner()
            } catch {
                XCTFail("💥 failed to save image with error \(error)")
            }

            saveExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        let readExpectation = self.expectation(description: "Read MrMinder")

        // recreate persistence so memory cache is empty
        persistence = diskMemoryPersistence(withDiskLimit: sizeLimit,
                                            memLimit: sizeLimit,
                                            extraPath: "Test9",
                                            performanceMetrics:  performanceMetrics,
                                            removeDir: false)

        let measure2 = self.expectation(description: "measure")
        measure2.expectedFulfillmentCount = 3

        performanceMetrics.measureInvokedClosure = { [count = VarBox(0)] identifier, metadata in
            if count.value == 0 {
                XCTAssertEqual(identifier, performanceMetrics.memoryReadIdentifier)
                XCTAssertDumpsEqual(metadata, [performanceMetrics.errorMetadataKey : Persistence.Error.noObjectForKey])
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

        persistence.object(for: "🎃") { (inner: () throws -> Data) in
            do {
                let imageData = try inner()

                XCTAssertEqual(imageData, mrMinderData)
            } catch {
                XCTFail("💥 trying to get object from disk. Error: \(error)")
            }

            readExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testNoObjectError_WhenWeTryToGetAnInexistingObjectWithPerformanceMetrics_ItShouldReturnNoObjectForKey() {
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
            } else {
                XCTAssertEqual(identifier, performanceMetrics.diskReadIdentifier)
            }
            XCTAssertDumpsEqual(metadata, [performanceMetrics.errorMetadataKey : Persistence.Error.noObjectForKey])
            count.value += 1
            measure.fulfill()
        }

        let expectation = self.expectation(description: "No object for key")
        persistence.object(for: "🚫") { (inner: () throws -> Data) in
            do {
                let _ = try inner()

                XCTFail("💥 found object for key 🚫 😳")
            } catch Persistence.Error.noObjectForKey {
                // 🤠 well done
            }
            catch {
                XCTFail("💥 should return `noObjectForKey` error but got error \(error)")
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }
}

fileprivate let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
fileprivate let testPath = cachePath + "/test"

fileprivate let mrMinder = imageFromFile(withName: "mr-minder", type: "png")

fileprivate func diskMemoryPersistence(withDiskLimit diskLimit: UInt64,
                                       memLimit: UInt64,
                                       extraPath: String = "test",
                                       performanceMetrics: PersistencePerformanceMetricsTracker? = nil,
                                       removeDir: Bool = true) -> DiskMemoryPersistenceStack {

    let testPath = cachePath + "/" + extraPath

    if removeDir {
        try? FileManager.default.removeItem(atPath: testPath)
    }

    let configuration = DiskMemoryPersistenceStack.Configuration(diskLimit: diskLimit,
                                                                 memLimit: memLimit,
                                                                 path: testPath,
                                                                 performanceMetrics: performanceMetrics,
                                                                 qos: (read: .userInteractive, write: .userInteractive))

    return DiskMemoryPersistenceStack(configuration: configuration)
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
                   into persistenceStack: DiskMemoryPersistenceStack,
                   expectation: XCTestExpectation) {

    persistenceStack.setObject(mrMinderData, for: key) { (inner: () throws -> ()) in
        do {
            try inner()
        } catch {
            XCTFail("💥 failed to save image with error \(error)")
        }
        
        expectation.fulfill()
    }

}

//
//  DiskMemoryPersistenceTestCase.swift
//  Alicerce
//
//  Created by Luís Portela on 13/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

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
}

fileprivate let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
fileprivate let testPath = cachePath + "/test"

fileprivate let mrMinder = imageFromFile(withName: "mr-minder", type: "png")

fileprivate func diskMemoryPersistence(withDiskLimit diskLimit: UInt64,
                                       memLimit: UInt64,
                                       extraPath: String = "test",
                                       removeDir: Bool = true) -> DiskMemoryPersistenceStack {

    let testPath = cachePath + "/" + extraPath

    if removeDir {
        try? FileManager.default.removeItem(atPath: testPath)
    }

    let configuration = DiskMemoryPersistenceStack.Configuration(diskLimit: diskLimit,
                                                                 memLimit: memLimit,
                                                                 path: testPath,
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

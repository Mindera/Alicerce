// Copyright © 2018 Mindera. All rights reserved.

import XCTest
import Result
@testable import Alicerce

class PersistencePerformanceMetricsTrackerTestCase: XCTestCase {

    private typealias MemoryAccessStopClosure =
        (_ result: Result<(blobSize: UInt64, memorySize: UInt64), MockError>) -> Void

    private typealias DiskAccessStopClosure =
        (_ result: Result<(blobSize: UInt64, diskSize: UInt64), MockError>) -> Void

    private enum MockError: Error {
        case 💩
    }

    private var tracker: MockPersistencePerformanceMetricsTracker!

    override func setUp() {
        super.setUp()

        tracker = MockPersistencePerformanceMetricsTracker()
    }

    override func tearDown() {
        tracker = nil

        super.tearDown()
    }

    // measureMemoryRead

    func testMeasureMemoryRead_WithSuccessfulRead_ShouldInvokeStartAndStopOnTheTrackerAndSucceed() {
        let measure = self.expectation(description: "measure")
        defer { waitForExpectations(timeout: 1) }

        let testBlobSize = UInt64(1337)
        let testUsedMemorySize = UInt64(9001)
        let testReturn = "🚀"

        tracker.measureInvokedClosure = { identifier, metadata in
            XCTAssertEqual(identifier, self.tracker.memoryReadIdentifier)
            XCTAssertDumpsEqual(metadata, [self.tracker.blobSizeMetadataKey : testBlobSize,
                                           self.tracker.usedMemoryMetadataKey : testUsedMemorySize])
            measure.fulfill()
        }

        let readReturn: String = tracker.measureMemoryRead { (stop: @escaping MemoryAccessStopClosure) in
            stop(.success((testBlobSize, testUsedMemorySize)))
            return testReturn
        }

        XCTAssertEqual(readReturn, testReturn)
    }

    func testMeasureMemoryRead_WithFailingRead_ShouldInvokeStartAndStopOnTheTrackerAndFail() {
        let measure = self.expectation(description: "measure")
        defer { waitForExpectations(timeout: 1) }

        let testError = MockError.💩

        tracker.measureInvokedClosure = { identifier, metadata in
            XCTAssertEqual(identifier, self.tracker.memoryReadIdentifier)
            XCTAssertDumpsEqual(metadata, [self.tracker.errorMetadataKey : testError])
            measure.fulfill()
        }

        do {
            let _: String = try tracker.measureMemoryRead { (stop: @escaping MemoryAccessStopClosure) in
                stop(.failure(testError))
                throw testError
            }
            XCTFail("unexpected success")
        } catch MockError.💩 {
            // expected error
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    // measureMemoryWrite

    func testMeasureMemoryWrite_WithSuccessfulRead_ShouldInvokeStartAndStopOnTheTrackerAndSucceed() {
        let measure = self.expectation(description: "measure")
        defer { waitForExpectations(timeout: 1) }

        let testBlobSize = UInt64(1337)
        let testUsedMemorySize = UInt64(9001)
        let testReturn = "🚀"

        tracker.measureInvokedClosure = { identifier, metadata in
            XCTAssertEqual(identifier, self.tracker.memoryWriteIdentifier)
            XCTAssertDumpsEqual(metadata, [self.tracker.blobSizeMetadataKey : testBlobSize,
                                           self.tracker.usedMemoryMetadataKey : testUsedMemorySize])
            measure.fulfill()
        }

        let readReturn: String = tracker.measureMemoryWrite { (stop: @escaping MemoryAccessStopClosure) in
            stop(.success((testBlobSize, testUsedMemorySize)))
            return testReturn
        }

        XCTAssertEqual(readReturn, testReturn)
    }

    func testMeasureMemoryWrite_WithFailingRead_ShouldInvokeStartAndStopOnTheTrackerAndFail() {
        let measure = self.expectation(description: "measure")
        defer { waitForExpectations(timeout: 1) }

        let testError = MockError.💩

        tracker.measureInvokedClosure = { identifier, metadata in
            XCTAssertEqual(identifier, self.tracker.memoryWriteIdentifier)
            XCTAssertDumpsEqual(metadata, [self.tracker.errorMetadataKey : testError])
            measure.fulfill()
        }

        do {
            let _: String = try tracker.measureMemoryWrite { (stop: @escaping MemoryAccessStopClosure) in
                stop(.failure(testError))
                throw testError
            }
            XCTFail("unexpected success")
        } catch MockError.💩 {
            // expected error
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    // measureDiskRead

    func testMeasureDiskRead_WithSuccessfulRead_ShouldInvokeStartAndStopOnTheTrackerAndSucceed() {
        let measure = self.expectation(description: "measure")
        defer { waitForExpectations(timeout: 1) }

        let testBlobSize = UInt64(1337)
        let testUsedDiskSize = UInt64(9001)
        let testReturn = "🚀"

        tracker.measureInvokedClosure = { identifier, metadata in
            XCTAssertEqual(identifier, self.tracker.diskReadIdentifier)
            XCTAssertDumpsEqual(metadata, [self.tracker.blobSizeMetadataKey : testBlobSize,
                                           self.tracker.usedDiskMetadataKey : testUsedDiskSize])
            measure.fulfill()
        }

        let readReturn: String = tracker.measureDiskRead { (stop: @escaping DiskAccessStopClosure) in
            stop(.success((testBlobSize, testUsedDiskSize)))
            return testReturn
        }

        XCTAssertEqual(readReturn, testReturn)
    }

    func testMeasureWriteRead_WithFailingRead_ShouldInvokeStartAndStopOnTheTrackerAndFail() {
        let measure = self.expectation(description: "measure")
        defer { waitForExpectations(timeout: 1) }

        let testError = MockError.💩

        tracker.measureInvokedClosure = { identifier, metadata in
            XCTAssertEqual(identifier, self.tracker.diskReadIdentifier)
            XCTAssertDumpsEqual(metadata, [self.tracker.errorMetadataKey : testError])
            measure.fulfill()
        }

        do {
            let _: String = try tracker.measureDiskRead { (stop: @escaping DiskAccessStopClosure) in
                stop(.failure(testError))
                throw testError
            }
            XCTFail("unexpected success")
        } catch MockError.💩 {
            // expected error
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    // measureDiskWrite

    func testMeasureDiskWrite_WithSuccessfulRead_ShouldInvokeStartAndStopOnTheTrackerAndSucceed() {
        let measure = self.expectation(description: "measure")
        defer { waitForExpectations(timeout: 1) }

        let testBlobSize = UInt64(1337)
        let testUsedDiskSize = UInt64(9001)
        let testReturn = "🚀"

        tracker.measureInvokedClosure = { identifier, metadata in
            XCTAssertEqual(identifier, self.tracker.diskWriteIdentifier)
            XCTAssertDumpsEqual(metadata, [self.tracker.blobSizeMetadataKey : testBlobSize,
                                           self.tracker.usedDiskMetadataKey : testUsedDiskSize])
            measure.fulfill()
        }

        let readReturn: String = tracker.measureDiskWrite { (stop: @escaping DiskAccessStopClosure) in
            stop(.success((testBlobSize, testUsedDiskSize)))
            return testReturn
        }

        XCTAssertEqual(readReturn, testReturn)
    }

    func testMeasureDiskWrite_WithFailingRead_ShouldInvokeStartAndStopOnTheTrackerAndFail() {
        let measure = self.expectation(description: "measure")
        defer { waitForExpectations(timeout: 1) }

        let testError = MockError.💩

        tracker.measureInvokedClosure = { identifier, metadata in
            XCTAssertEqual(identifier, self.tracker.diskWriteIdentifier)
            XCTAssertDumpsEqual(metadata, [self.tracker.errorMetadataKey : testError])
            measure.fulfill()
        }

        do {
            let _: String = try tracker.measureDiskWrite { (stop: @escaping DiskAccessStopClosure) in
                stop(.failure(testError))
                throw testError
            }
            XCTFail("unexpected success")
        } catch MockError.💩 {
            // expected error
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }
}

final class MockPersistencePerformanceMetricsTracker: MockPerformanceMetricsTracker,
                                                      PersistencePerformanceMetricsTracker {

    // mocks

    var mockUsedMemoryMetadataKey: String = "total_ram"
    var mockUsedDiskMetadataKey: String = "total_disk"
    var mockBlobSizeMetadataKey: String = "size"
    var mockErrorMetadataKey: String = "error"

    var mockMemoryReadIdentifier: PerformanceMetricsTracker.Identifier = "read_memory"
    var mockMemoryWriteIdentifier: PerformanceMetricsTracker.Identifier = "write_memory"
    var mockDiskReadIdentifier: PerformanceMetricsTracker.Identifier = "read_disk"
    var mockDiskWriteIdentifier: PerformanceMetricsTracker.Identifier = "write_disk"

    // PersistencePerformanceMetricsTracker

    var usedMemoryMetadataKey: String { return mockUsedMemoryMetadataKey }
    var usedDiskMetadataKey: String { return mockUsedDiskMetadataKey }
    var blobSizeMetadataKey: String { return mockBlobSizeMetadataKey }
    var errorMetadataKey: String { return mockErrorMetadataKey }

    var memoryReadIdentifier: PerformanceMetricsTracker.Identifier { return mockMemoryReadIdentifier }
    var memoryWriteIdentifier: PerformanceMetricsTracker.Identifier { return mockMemoryWriteIdentifier}
    var diskReadIdentifier: PerformanceMetricsTracker.Identifier { return mockDiskReadIdentifier }
    var diskWriteIdentifier: PerformanceMetricsTracker.Identifier { return mockDiskWriteIdentifier }
}

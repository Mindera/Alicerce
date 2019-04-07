import XCTest
@testable import Alicerce

class NetworkStorePerformanceMetricsTrackerTestCase: XCTestCase {

    private struct MockDecodableResource: DecodableResource {

        enum MockError: Swift.Error { case 💥 }

        var mockDecode: DecodeClosure = { _ in throw MockError.💥 }

        typealias Internal = Int
        typealias External = String

        var decode: DecodeClosure { return mockDecode }
    }

    private var tracker: MockNetworkStorePerformanceMetricsTracker!
    
    override func setUp() {
        super.setUp()

        tracker = MockNetworkStorePerformanceMetricsTracker()
    }
    
    override func tearDown() {
        tracker = nil

        super.tearDown()
    }

    // measureDecode

    func testMeasureDecode_WithSuccessfulDecode_ShouldInvokeStartAndStopOnTheTrackerAndSucceed() {
        let measure = self.expectation(description: "measure")
        defer { waitForExpectations(timeout: 1) }

        var testResource = MockDecodableResource()
        let testPayload = "🎁"
        let testParsedResult = 1337
        let testMetadata: PerformanceMetrics.Metadata = [ "📈" : 9000, "🔨" : false]

        tracker.measureSyncInvokedClosure = { identifier, metadata in
            XCTAssertEqual(identifier, self.tracker.makeDecodeIdentifier(for: testResource, payload: testPayload))
            XCTAssertDumpsEqual(metadata, testMetadata)
            measure.fulfill()
        }

        testResource.mockDecode = { remote in
            XCTAssertEqual(remote, testPayload)
            return testParsedResult
        }

        do {
            let result = try tracker.measureDecode(of: testResource, payload: testPayload, metadata: testMetadata) {
                try testResource.decode(testPayload)
            }
            XCTAssertEqual(testParsedResult, result)
        } catch {
            XCTFail("unexpected error \(error)!")
        }
    }

    func testMeasureParse_WithFailingParse_ShouldInvokeStartAndStopOnTheTrackerAndFail() {
        let measure = self.expectation(description: "measure")
        defer { waitForExpectations(timeout: 1) }

        var testResource = MockDecodableResource()
        let testPayload = "💣"
        let testMetadata: PerformanceMetrics.Metadata = [ "📈" : 9001, "🔨" : false]

        tracker.measureSyncInvokedClosure = { identifier, metadata in
            XCTAssertEqual(identifier, self.tracker.makeDecodeIdentifier(for: testResource, payload: testPayload))
            XCTAssertDumpsEqual(metadata, testMetadata)
            measure.fulfill()
        }

        testResource.mockDecode = { remote in
            XCTAssertEqual(remote, testPayload)
            throw MockDecodableResource.MockError.💥
        }

        do {
            let _ = try tracker.measureDecode(of: testResource, payload: testPayload, metadata: testMetadata) {
                try testResource.decode(testPayload)
            }
            XCTFail("unexpected error success!")
        } catch MockDecodableResource.MockError.💥 {
            // expected error
        } catch {
            XCTFail("unexpected error \(error)!")
        }
    }
}

final class MockNetworkStorePerformanceMetricsTracker: MockPerformanceMetricsTracker,
                                                       NetworkStorePerformanceMetricsTracker {
}

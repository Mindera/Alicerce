import XCTest
@testable import Alicerce

class StackOrchestratorPerformanceMetricsTrackerTestCase: XCTestCase {

    private var tracker: MockStackOrchestratorPerformanceMetricsTracker!
    
    override func setUp() {
        super.setUp()

        tracker = MockStackOrchestratorPerformanceMetricsTracker()
    }
    
    override func tearDown() {
        tracker = nil

        super.tearDown()
    }

    // measureDecode

    func testMeasureDecode_WithSuccessfulDecode_ShouldInvokeStartAndStopOnTheTrackerAndSucceed() {
        let expectation = self.expectation(description: "measure")
        defer { waitForExpectations(timeout: 1) }

        let testResource = "📦"
        let testPayload = "🎁"
        let testParsedResult = 1337
        let testMetadata: PerformanceMetrics.Metadata = [tracker.modelTypeMetadataKey: "Int"]

        tracker.measureSyncInvokedClosure = { identifier, metadata in
            XCTAssertEqual(
                identifier,
                self.tracker.makeDecodeIdentifier(for: testResource, payload: testPayload, result: Int.self)
            )
            XCTAssertDumpsEqual(metadata, testMetadata)
            expectation.fulfill()
        }

        XCTAssertEqual(
            testParsedResult,
            tracker.measureDecode(of: testResource, payload: testPayload, decode: { testParsedResult })
        )
    }

    func testMeasureDecode_WithFailingDecode_ShouldInvokeStartAndStopOnTheTrackerAndFail() {
        let expectation = self.expectation(description: "measure")
        defer { waitForExpectations(timeout: 1) }

        let testResource = "📦"
        let testPayload = "💣"
        let testMetadata: PerformanceMetrics.Metadata = [tracker.modelTypeMetadataKey: "Int"]

        tracker.measureSyncInvokedClosure = { identifier, metadata in
            XCTAssertEqual(
                identifier,
                self.tracker.makeDecodeIdentifier(for: testResource, payload: testPayload, result: Int.self)
            )
            XCTAssertDumpsEqual(metadata, testMetadata)
            expectation.fulfill()
        }

        enum MockError: Error { case 💥 }

        XCTAssertThrowsError(
            try tracker.measureDecode(of: testResource, payload: testPayload, decode: { throw MockError.💥 }) as Int,
            "unexpected success!"
        ) {
            guard case MockError.💥 = $0 else {
                XCTFail("unexpected error \($0)!")
                return
            }
        }
    }
}

final class MockStackOrchestratorPerformanceMetricsTracker:
    MockPerformanceMetricsTracker, StackOrchestratorPerformanceMetricsTracker
{}

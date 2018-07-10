import XCTest
@testable import Alicerce

class NetworkStorePerformanceMetricsTrackerTestCase: XCTestCase {

    private struct MockResource: Resource {

        var mockParse: (Remote) throws -> Local = { _ in throw MockError.💥 }

        enum MockError: Swift.Error { case 💥 }

        typealias Remote = String
        typealias Local = Int
        typealias Error = MockError

        var parse: ResourceMapClosure<Remote, Local> { return mockParse }
        var serialize: ResourceMapClosure<Local, Remote> { fatalError() }
        var errorParser: ResourceErrorParseClosure<Remote, Error> { fatalError() }
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

    // measureParse

    func testMeasureParse_WithSuccessfulParse_ShouldInvokeStartAndStopOnTheTrackerAndSucceed() {
        let measure = self.expectation(description: "measure")
        defer { waitForExpectations(timeout: 1) }

        var testResource = MockResource()
        let testPayload = "🎁"
        let testParsedResult = 1337
        let testMetadata: PerformanceMetrics.Metadata = [ "📈" : 9000, "🔨" : false]

        tracker.measureSyncInvokedClosure = { identifier, metadata in
            XCTAssertEqual(identifier, self.tracker.makeParseIdentifier(for: testResource, payload: testPayload))
            XCTAssertDumpsEqual(metadata, testMetadata)
            measure.fulfill()
        }

        testResource.mockParse = { remote in
            XCTAssertEqual(remote, testPayload)
            return testParsedResult
        }

        do {
            let result = try tracker.measureParse (of: testResource, payload: testPayload, metadata: testMetadata) {
                try testResource.parse(testPayload)
            }
            XCTAssertEqual(testParsedResult, result)
        } catch {
            XCTFail("unexpected error \(error)!")
        }
    }

    func testMeasureParse_WithFailingParse_ShouldInvokeStartAndStopOnTheTrackerAndFail() {
        let measure = self.expectation(description: "measure")
        defer { waitForExpectations(timeout: 1) }

        var testResource = MockResource()
        let testPayload = "💣"
        let testMetadata: PerformanceMetrics.Metadata = [ "📈" : 9001, "🔨" : false]

        tracker.measureSyncInvokedClosure = { identifier, metadata in
            XCTAssertEqual(identifier, self.tracker.makeParseIdentifier(for: testResource, payload: testPayload))
            XCTAssertDumpsEqual(metadata, testMetadata)
            measure.fulfill()
        }

        testResource.mockParse = { remote in
            XCTAssertEqual(remote, testPayload)
            throw MockResource.MockError.💥
        }

        do {
            let _ = try tracker.measureParse (of: testResource, payload: testPayload, metadata: testMetadata) {
                try testResource.parse(testPayload)
            }
            XCTFail("unexpected error success!")
        } catch MockResource.MockError.💥 {
            // expected error
        } catch {
            XCTFail("unexpected error \(error)!")
        }
    }
}

final class MockNetworkStorePerformanceMetricsTracker: MockPerformanceMetricsTracker,
                                                       NetworkStorePerformanceMetricsTracker {
}

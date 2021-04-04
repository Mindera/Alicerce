import XCTest
@testable import Alicerce

class ConsoleLogDestinationsTestCase: XCTestCase {

    typealias ConsoleLogDestination = Log.ConsoleLogDestination<MockStringLogItemFormatter, AnyHashable>

    private var destination: ConsoleLogDestination!

    private var formatter: MockStringLogItemFormatter!

    private var outputClosureInvoked: ConsoleLogDestination.OutputClosure?

    fileprivate let expectationTimeout: TimeInterval = 5
    fileprivate let expectationHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("🔥: Test expectation wait timed out: \(error)")
        }
    }

    override func setUp() {

        super.setUp()

        formatter = MockStringLogItemFormatter()
        destination = ConsoleLogDestination(
            formatter: formatter,
            minLevel: .verbose,
            output: { [weak self] in self?.outputClosureInvoked?($0, $1) },
            logMetadata: nil
        )
    }

    override func tearDown() {

        outputClosureInvoked = nil
        formatter = nil
        destination = nil

        super.tearDown()
    }

    // write

    func testWrite_WithNonEmptyFormattedMessage_ShouldCallOutputClosure() {

        let formatExpectation = self.expectation(description: "write format")
        let outputExpectation = self.expectation(description: "write output")
        defer { waitForExpectations(timeout: 1) }

        let item = Log.Item.testItem
        let testLog = "🗒"

        formatter.mockFormat = {
            XCTAssertEqual($0, item)
            formatExpectation.fulfill()
            return testLog
        }

        outputClosureInvoked = {
            defer { outputExpectation.fulfill() }
            XCTAssertEqual($0, item.level)
            XCTAssertEqual($1, testLog)
        }

        destination.write(item: item) { XCTFail("unexpected error \($0)") }
    }

    func testWrite_WithThrowingFormat_ShouldCallFailureClosure() {

        let formatExpectation = self.expectation(description: "write format")
        let errorExpectation = self.expectation(description: "write error")
        defer { waitForExpectations(timeout: 1) }

        let item = Log.Item.testItem

        enum MockError: Error { case 🔥 }

        formatter.mockFormat = { _ in
            defer { formatExpectation.fulfill()}
            throw MockError.🔥
        }
        
        outputClosureInvoked = { _, _ in XCTFail("unexpected call!") }

        destination.write(item: item) {
            switch $0 {
            case let Log.ConsoleLogDestinationError.itemFormatFailed(errorItem, MockError.🔥):
                XCTAssertEqual(errorItem, item)
            default: XCTFail("unexpected error \($0)")
            }
            errorExpectation.fulfill()
        }
    }

    func testWrite_WithEmptyFormattedString_ShouldNotInvokeOutputClosure() {

        let formatExpectation = self.expectation(description: "write format")
        defer { waitForExpectations(timeout: 1) }

        formatter.mockFormat = { _ in
            formatExpectation.fulfill()
            return ""
        }

        outputClosureInvoked = { _, _ in XCTFail("unexpected call!") }

        destination.write(item: Log.Item.testItem) { XCTFail("unexpected error \($0)") }
    }

    // setMetadata

    func testSetMetadata_WithNilLogMetadataClosure_ShouldDoNothing() {

        outputClosureInvoked = { _, _ in XCTFail("unexpected call!") }

        destination.setMetadata(["π" : Double.pi], onFailure: { XCTFail("unexpected error \($0)") })
    }

    func testSetMetadata_WitEmptyMetadataData_ShouldDoNothing() {

        let metadataExpectation = self.expectation(description: "set metadata")
        defer { waitForExpectations(timeout: 1) }

        let testMetadata: [AnyHashable : Any] = [1337 : "1337", "test" : 1337, "π" : Double.pi]
        let metadataLevel = Log.Level.error

        let logMetadata: ConsoleLogDestination.LogMetadataClosure = {
            defer { metadataExpectation.fulfill() }
            XCTAssertDumpsEqual($0, testMetadata)
            return(metadataLevel, "")
        }

        destination = ConsoleLogDestination(
            formatter: formatter,
            minLevel: .verbose,
            output: { _, _ in XCTFail("unexpected call!") },
            logMetadata: logMetadata
        )

        destination.setMetadata(testMetadata, onFailure: { XCTFail("unexpected error \($0)") })
    }

    func testSetMetadata_WithNonEmptyMetadataData_ShouldCallOutputClosure() {

        let metadataExpectation = self.expectation(description: "set metadata")
        let outputExpectation = self.expectation(description: "set metadata output")
        defer { waitForExpectations(timeout: 1) }

        let testMetadata: [AnyHashable : Any] = [1337 : "1337", "test" : 1337, "π" : Double.pi]
        let metadataLevel = Log.Level.error
        let metadataMessage = "📝"

        let logMetadata: ConsoleLogDestination.LogMetadataClosure = {
            defer { metadataExpectation.fulfill() }
            XCTAssertDumpsEqual($0, testMetadata)
            return(metadataLevel, metadataMessage)
        }

        let outputClosure: ConsoleLogDestination.OutputClosure = {
            defer { outputExpectation.fulfill() }
            XCTAssertEqual($0, metadataLevel)
            XCTAssertEqual($1, metadataMessage)
        }

        destination = ConsoleLogDestination(
            formatter: formatter,
            minLevel: .verbose,
            output: outputClosure,
            logMetadata: logMetadata
        )

        destination.setMetadata(testMetadata, onFailure: { XCTFail("unexpected error \($0)") })
    }

    // removeMetadata

    func testRemoveMetadata_ShouldDoNothing() {
        
        destination.removeMetadata(forKeys: [], onFailure: { XCTFail("unexpected error \($0)") }) // dummy test
    }
}

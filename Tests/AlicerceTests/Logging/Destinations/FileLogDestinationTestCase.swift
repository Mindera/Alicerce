import XCTest
@testable import Alicerce

class FileLogDestinationTestCase: XCTestCase {

    typealias FileLogDestination = Log.FileLogDestination<MockDataLogItemFormatter, AnyHashable>

    typealias FileLogDestinationError = FileLogDestination.FileLogDestinationError

    private var destination: FileLogDestination!

    private var formatter: MockDataLogItemFormatter!
    private var logfileURL: URL!
    private var fileManager: MockFileManager!
    private var queue: Log.Queue!

    private let nonExistingLogfileURL = URL(fileURLWithPath: "/non_existing_folder/Log.log")

    override func setUp() {
        super.setUp()

        formatter = MockDataLogItemFormatter()

        logfileURL = URL(fileURLWithPath: "/tmp/Log.log")
        try? FileManager.default.removeItem(at: logfileURL)

        fileManager = MockFileManager()
        queue = Log.Queue(label: "com.mindera.alicerce.FileLogDestinationTestCase")
        destination = FileLogDestination(formatter: formatter,
                                         fileURL: logfileURL,
                                         fileManager: fileManager,
                                         minLevel: .verbose,
                                         queue: queue,
                                         logMetadata: nil)
    }

    override func tearDown() {
        destination = nil
        queue = nil
        fileManager = nil
        logfileURL = nil
        formatter = nil

        super.tearDown()
    }

    // clear

    func testClear_WithExistingFileAndSuccessfulWrite_ShouldRemoveFile() {

        fileManager.mockFileExists = {
            XCTAssertEqual($0, self.logfileURL.path)
            return true
        }

        fileManager.mockRemoveItemAtURL = {
            XCTAssertEqual($0, self.logfileURL)
            return
        }

        do {
            try destination.clear()
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    func testClear_WithNonExistingFile_ShouldIgnoreCall() {

        fileManager.mockFileExists = {
            XCTAssertEqual($0, self.logfileURL.path)
            return false
        }

        fileManager.mockRemoveItemAtURL = { _ in
            XCTFail("unexpected removeItem call")
            return
        }

        do {
            try destination.clear()
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    func testClear_WithExistingFileAndUnsuccessfulWrite_ShouldFail() {

        enum MockError: Error {
            case 💥
        }

        fileManager.mockFileExists = {
            XCTAssertEqual($0, self.logfileURL.path)
            return true
        }

        fileManager.mockRemoveItemAtURL = {
            XCTAssertEqual($0, self.logfileURL)
            throw MockError.💥
        }

        do {
            try destination.clear()
            XCTFail("unexpected success!")
        } catch FileLogDestinationError.clearFailed(let URL, MockError.💥) {
            XCTAssertEqual(URL, logfileURL)
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    // write

    func testWrite_WithNonEmptyFormattedDataAndNonExistingFile_ShouldCreateFile() {
        let formatExpectation = self.expectation(description: "write format")
        let fileExistsExpectation = self.expectation(description: "write fileExists")
        defer { waitForExpectations(timeout: 1) }

        let item = Log.Item.testItem
        let testLog = "🗒"

        formatter.mockFormat = {
            XCTAssertEqual($0, item)
            formatExpectation.fulfill()
            return testLog.data(using: .utf8)!
        }

        fileManager.mockFileExists = {
            XCTAssertEqual($0, self.logfileURL.path)
            fileExistsExpectation.fulfill()
            return false
        }

        destination.write(item: item) { XCTFail("unexpected error \($0)") }

        queue.dispatchQueue.sync {
            let content = logfileContent(logfileURL: logfileURL)
            XCTAssertEqual(content, testLog)
        }
    }

    func testWrite_WithNonEmptyFormattedDataAndExistingFile_ShouldAppendToFile() {
        let formatExpectation = self.expectation(description: "write format")
        let fileExistsExpectation = self.expectation(description: "write fileExists")
        defer { waitForExpectations(timeout: 1) }

        let existingLog = "📝"
        try! existingLog.data(using: .utf8)!.write(to: logfileURL)

        let item = Log.Item.testItem
        let testLog = "🗒"

        formatter.mockFormat = {
            XCTAssertEqual($0, item)
            formatExpectation.fulfill()
            return testLog.data(using: .utf8)!
        }

        fileManager.mockFileExists = {
            XCTAssertEqual($0, self.logfileURL.path)
            fileExistsExpectation.fulfill()
            return true
        }

        destination.write(item: item) { XCTFail("unexpected error \($0)") }

        queue.dispatchQueue.sync {
            let content = logfileContent(logfileURL: logfileURL)
            XCTAssertEqual(content, existingLog + "\n" + testLog)
        }
    }

    func testWrite_WithThrowingFormat_ShouldCallFailureClosure() {
        let formatExpectation = self.expectation(description: "write format")
        let errorExpectation = self.expectation(description: "write error")
        defer { waitForExpectations(timeout: 1) }

        let item = Log.Item.testItem

        enum MockError: Error { case 🔥 }

        formatter.mockFormat = { _ in
            formatExpectation.fulfill()
            throw MockError.🔥
        }
        
        fileManager.mockFileExists = { _ in
            XCTFail("unexpected call!")
            return false
        }

        destination.write(item: item) {
            switch $0 {
            case let FileLogDestinationError.itemFormatFailed(errorItem, MockError.🔥):
                XCTAssertEqual(errorItem, item)
            default: XCTFail("unexpected error \($0)")
            }
            errorExpectation.fulfill()
        }

        queue.dispatchQueue.sync {
            let content = logfileContent(logfileURL: logfileURL)
            XCTAssert(content.isEmpty)
        }
    }

    func testWrite_WithEmptyFormattedData_ShouldNotWriteToFile() {
        let formatExpectation = self.expectation(description: "write format")
        defer { waitForExpectations(timeout: 1) }

        formatter.mockFormat = { _ in
            formatExpectation.fulfill()
            return Data()
        }
        fileManager.mockFileExists = { _ in
            XCTFail("unexpected call!")
            return true
        }

        destination.write(item: Log.Item.testItem) { XCTFail("unexpected error \($0)") }

        queue.dispatchQueue.sync {
            let content = logfileContent(logfileURL: logfileURL)
            XCTAssert(content.isEmpty)
        }
    }

    func testWrite_WithFalseFileExistsAndNonExistentPath_ShouldCallFailureClosure() {
        let errorExpectation = self.expectation(description: "write error")
        defer { waitForExpectations(timeout: 1) }

        destination = Log.FileLogDestination(formatter: formatter,
                                             fileURL: nonExistingLogfileURL,
                                             fileManager: fileManager,
                                             minLevel: .verbose,
                                             queue: queue,
                                             logMetadata: nil)

        let item = Log.Item.testItem
        let testLog = "🗒"

        formatter.mockFormat = { _ in testLog.data(using: .utf8)! }
        fileManager.mockFileExists = { _ in false }

        destination.write(item: item) {
            switch $0 {
            case let FileLogDestinationError.itemWriteFailed(url, errorItem, error as NSError)
            where error.domain == NSCocoaErrorDomain && error.code == NSFileNoSuchFileError:
                XCTAssertEqual(url, self.nonExistingLogfileURL)
                XCTAssertEqual(errorItem, item)
            default: XCTFail("unexpected error \($0)")
            }
            errorExpectation.fulfill()
        }

        queue.dispatchQueue.sync {
            let content = logfileContent(logfileURL: nonExistingLogfileURL)
            XCTAssert(content.isEmpty)
        }
    }

    func testWrite_WithTrueFileExistsAndNonExistentPath_ShouldCallFailureClosure() {
        let errorExpectation = self.expectation(description: "write error")
        defer { waitForExpectations(timeout: 1) }

        destination = Log.FileLogDestination(formatter: formatter,
                                             fileURL: nonExistingLogfileURL,
                                             fileManager: fileManager,
                                             minLevel: .verbose,
                                             queue: queue,
                                             logMetadata: nil)

        let item = Log.Item.testItem
        let testLog = "🗒"

        formatter.mockFormat = { _ in testLog.data(using: .utf8)! }
        fileManager.mockFileExists = { _ in true }

        destination.write(item: item) {
            switch $0 {
            case let FileLogDestinationError.itemWriteFailed(url, errorItem, error as NSError)
            where error.domain == NSCocoaErrorDomain && error.code == NSFileNoSuchFileError:
                XCTAssertEqual(url, self.nonExistingLogfileURL)
                XCTAssertEqual(errorItem, item)
            default: XCTFail("unexpected error \($0)")
            }
            errorExpectation.fulfill()
        }

        queue.dispatchQueue.sync {
            let content = logfileContent(logfileURL: nonExistingLogfileURL)
            XCTAssert(content.isEmpty)
        }
    }

    // setMetadata

    func testSetMetadata_WithNilLogMetadataClosure_ShouldDoNothing() {
        fileManager.mockFileExists = { _ in
            XCTFail("unexpected call!")
            return true
        }

        destination.setMetadata(["π" : Double.pi], onFailure: { XCTFail("unexpected error \($0)") })

        queue.dispatchQueue.sync {
            let content = logfileContent(logfileURL: self.logfileURL)
            XCTAssert(content.isEmpty)
        }
    }

    func testSetMetadata_WitEmptyMetadataData_ShouldDoNothing() {
        let metadataExpectation = self.expectation(description: "set metadata")
        defer { waitForExpectations(timeout: 1) }

        let testMetadata: [AnyHashable : Any] = [1337 : "1337", "test" : 1337, "π" : Double.pi]

        let logMetadata: FileLogDestination.LogMetadataClosure = {
            XCTAssertDumpsEqual($0, testMetadata)
            metadataExpectation.fulfill()
            return Data()
        }

        fileManager.mockFileExists = { _ in
            XCTFail("unexpected call!")
            return true
        }

        destination = Log.FileLogDestination(formatter: formatter,
                                             fileURL: logfileURL,
                                             fileManager: fileManager,
                                             minLevel: .verbose,
                                             queue: queue,
                                             logMetadata: logMetadata)


        destination.setMetadata(testMetadata, onFailure: { XCTFail("unexpected error \($0)") })

        queue.dispatchQueue.sync {
            let content = logfileContent(logfileURL: self.logfileURL)
            XCTAssert(content.isEmpty)
        }
    }

    func testSetMetadata_WithNonExistentFile_ShouldCreateFile() {
        let metadataExpectation = self.expectation(description: "set metadata")
        let fileExistsExpectation = self.expectation(description: "write fileExists")
        defer { waitForExpectations(timeout: 1) }

        let testMetadata: [AnyHashable : Any] = [1337 : "1337", "test" : 1337, "π" : Double.pi]
        let testMetadataLog = testMetadata.description

        let logMetadata: FileLogDestination.LogMetadataClosure = {
            XCTAssertDumpsEqual($0, testMetadata)
            metadataExpectation.fulfill()
            return testMetadataLog.data(using: .utf8)!
        }

        fileManager.mockFileExists = {
            XCTAssertEqual($0, self.logfileURL.path)
            fileExistsExpectation.fulfill()
            return false
        }

        destination = Log.FileLogDestination(formatter: formatter,
                                             fileURL: logfileURL,
                                             fileManager: fileManager,
                                             minLevel: .verbose,
                                             queue: queue,
                                             logMetadata: logMetadata)


        destination.setMetadata(testMetadata, onFailure: { XCTFail("unexpected error \($0)") })

        queue.dispatchQueue.sync {
            let content = logfileContent(logfileURL: self.logfileURL)
            XCTAssertEqual(content, testMetadataLog)
        }
    }

    func testSetMetadata_WithExistentFile_ShouldAppendToFile() {
        let metadataExpectation = self.expectation(description: "set metadata")
        let fileExistsExpectation = self.expectation(description: "write fileExists")
        defer { waitForExpectations(timeout: 1) }

        let existingLog = "📝"
        try! existingLog.data(using: .utf8)!.write(to: logfileURL)

        let testMetadata: [AnyHashable : Any] = [1337 : "1337", "test" : 1337, "π" : Double.pi]
        let testMetadataLog = testMetadata.description

        let logMetadata: FileLogDestination.LogMetadataClosure = {
            XCTAssertDumpsEqual($0, testMetadata)
            metadataExpectation.fulfill()
            return testMetadataLog.data(using: .utf8)!
        }

        fileManager.mockFileExists = {
            XCTAssertEqual($0, self.logfileURL.path)
            fileExistsExpectation.fulfill()
            return true
        }

        destination = Log.FileLogDestination(formatter: formatter,
                                             fileURL: logfileURL,
                                             fileManager: fileManager,
                                             minLevel: .verbose,
                                             queue: queue,
                                             logMetadata: logMetadata)


        destination.setMetadata(testMetadata, onFailure: { XCTFail("unexpected error \($0)") })

        queue.dispatchQueue.sync {
            let content = logfileContent(logfileURL: self.logfileURL)
            XCTAssertEqual(content, existingLog + "\n" + testMetadataLog)
        }
    }

    func testSetMetadata_WithFalseFileExistsAndNotExistentPath_ShouldCallFailureClosure() {
        let metadataExpectation = self.expectation(description: "set metadata")
        let fileExistsExpectation = self.expectation(description: "write fileExists")
        defer { waitForExpectations(timeout: 1) }

        let testMetadata: [AnyHashable : Any] = [1337 : "1337", "test" : 1337, "π" : Double.pi]
        let testMetadataLogData = testMetadata.description.data(using: .utf8)!

        let logMetadata: FileLogDestination.LogMetadataClosure = {
            XCTAssertDumpsEqual($0, testMetadata)
            metadataExpectation.fulfill()
            return testMetadataLogData
        }

        fileManager.mockFileExists = {
            XCTAssertEqual($0, self.nonExistingLogfileURL.path)
            fileExistsExpectation.fulfill()
            return false
        }

        destination = Log.FileLogDestination(formatter: formatter,
                                             fileURL: nonExistingLogfileURL,
                                             fileManager: fileManager,
                                             minLevel: .verbose,
                                             queue: queue,
                                             logMetadata: logMetadata)


        destination.setMetadata(testMetadata, onFailure: {
            switch $0 {
            case let FileLogDestinationError.metadataWriteFailed(url, metadata, data, error as NSError)
            where error.domain == NSCocoaErrorDomain && error.code == NSFileNoSuchFileError:
                XCTAssertEqual(url, self.nonExistingLogfileURL)
                XCTAssertDumpsEqual(metadata, testMetadata)
                XCTAssertEqual(data, testMetadataLogData)
            default:
                XCTFail("unexpected error \($0)")
            }
        })

        queue.dispatchQueue.sync {
            let content = logfileContent(logfileURL: self.nonExistingLogfileURL)
            XCTAssert(content.isEmpty)
        }
    }

    func testSetMetadata_WithTrueFileExistsAndNonExistentPath_ShouldCallFailureClosure() {
        let metadataExpectation = self.expectation(description: "set metadata")
        let fileExistsExpectation = self.expectation(description: "write fileExists")
        defer { waitForExpectations(timeout: 1) }

        let testMetadata: [AnyHashable : Any] = [1337 : "1337", "test" : 1337, "π" : Double.pi]
        let testMetadataLogData = testMetadata.description.data(using: .utf8)!

        let logMetadata: FileLogDestination.LogMetadataClosure = {
            defer { metadataExpectation.fulfill() }
            XCTAssertDumpsEqual($0, testMetadata)
            return testMetadataLogData
        }

        fileManager.mockFileExists = {
            XCTAssertEqual($0, self.nonExistingLogfileURL.path)
            fileExistsExpectation.fulfill()
            return true
        }

        destination = Log.FileLogDestination(formatter: formatter,
                                             fileURL: nonExistingLogfileURL,
                                             fileManager: fileManager,
                                             minLevel: .verbose,
                                             queue: queue,
                                             logMetadata: logMetadata)


        destination.setMetadata(testMetadata, onFailure: {
            switch $0 {
            case let FileLogDestinationError.metadataWriteFailed(url, metadata, data, error as NSError)
            where error.domain == NSCocoaErrorDomain && error.code == NSFileNoSuchFileError:
                XCTAssertEqual(url, self.nonExistingLogfileURL)
                XCTAssertDumpsEqual(metadata, testMetadata)
                XCTAssertEqual(data, testMetadataLogData)
            default:
                XCTFail("unexpected error \($0)")
            }
        })

        queue.dispatchQueue.sync {
            let content = logfileContent(logfileURL: self.nonExistingLogfileURL)
            XCTAssert(content.isEmpty)
        }
    }

    // removeMetadata

    func testRemoveMetadata_ShouldDoNothing() {
        destination.removeMetadata(forKeys: [], onFailure: { XCTFail("unexpected error \($0)") }) // dummy test
    }

    // MARK: - Private methods

    private func logfileContent(logfileURL: URL) -> String {
        
        let content = (try? String(contentsOf: logfileURL)) ?? ""
        return content
    }
}

final class MockFileManager: FileManager {

    var fileExistsInvoked: ((String) -> Void)?
    var removeItemAtURLInvoked: ((URL) -> Void)?

    var mockFileExists: ((String) -> Bool)?
    var mockRemoveItemAtURL: ((URL) throws -> Void)?

    override func fileExists(atPath path: String) -> Bool {
        fileExistsInvoked?(path)
        return mockFileExists?(path) ?? super.fileExists(atPath: path)
    }

    override func removeItem(at URL: URL) throws {
        removeItemAtURLInvoked?(URL)
        try mockRemoveItemAtURL?(URL) ?? super.removeItem(at: URL)
    }

}

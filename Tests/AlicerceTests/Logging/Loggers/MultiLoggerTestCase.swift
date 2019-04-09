import XCTest
@testable import Alicerce

class MultiLoggerTestCase: XCTestCase {

    enum MockError: Error { case 😱 }
    enum MockLogModule: String, LogModule { case 🏗, 🚧 }
    enum MockMetadataKey { case 👤, 📱, 📊 }

    typealias MockLogDestination = MockMetadataLogDestination<MockLogModule, MockMetadataKey>
    typealias MultiLogger = Log.MultiLogger<MockLogModule, MockMetadataKey>

    private var log: MultiLogger!

    override func setUp() {
        super.setUp()

        log = MultiLogger()
    }

    override func tearDown() {
        log = nil

        super.tearDown()
    }

    // registerDestination

    func testRegisterDestination_WithUniqueIDs_ShouldSucceed() {

        let destination1 = MockLogDestination(id: "1")
        let destination2 = MockLogDestination(id: "2")

        do {
            try log.registerDestination(destination1)
            XCTAssertEqual(log.destinations.count, 1)
            try log.registerDestination(destination2)
            XCTAssertEqual(log.destinations.count, 2)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }
    }

    func testRegisterDestination_WithDuplicateIDs_ShouldFail() {

        let destination = MockLogDestination()

        do {
            try log.registerDestination(destination)
            XCTAssertEqual(log.destinations.count, 1)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }

        do {
            try log.registerDestination(destination)
        } catch Log.MultiLoggerError.duplicateDestination(let id) {
            XCTAssertEqual(id, destination.id)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }
    }

    // unregisterDestination

    func testUnregisterDestination_WithExistingID_ShouldSucceed() {

        let destination = MockLogDestination()

        do {
            try log.registerDestination(destination)
            XCTAssertEqual(log.destinations.count, 1)
            try log.unregisterDestination(destination)
            XCTAssertEqual(log.destinations.count, 0)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }
    }

    func testUnregisterDestination_WithNonExistingIDs_ShouldFail() {

        let destination = MockLogDestination()

        do {
            XCTAssertEqual(log.destinations.count, 0)
            try log.unregisterDestination(destination)
        } catch Log.MultiLoggerError.inexistentDestination(let id) {
            XCTAssertEqual(id, destination.id)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }
    }

    // registerModule

    func testRegisterModule_WithUniqueRawValue_ShouldSucceed() {

        do {
            try log.registerModule(.🏗, minLevel: .verbose)
            XCTAssertEqual(log.modules.count, 1)
            try log.registerModule(.🚧, minLevel: .verbose)
            XCTAssertEqual(log.modules.count, 2)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }
    }

    func testRegisterModule_WithDuplicateRawValue_ShouldFail() {

        let module = MockLogModule.🏗

        do {
            try log.registerModule(module, minLevel: .verbose)
            XCTAssertEqual(log.modules.count, 1)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }

        do {
            try log.registerModule(module, minLevel: .warning)
        } catch Log.MultiLoggerError.duplicateModule(let rawValue) {
            XCTAssertEqual(rawValue, module.rawValue)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }
    }

    // unregisterModule

    func testUnregisterModule_WithExistingRawValue_ShouldSucceed() {

        let module = MockLogModule.🚧

        do {
            try log.registerModule(module, minLevel: .verbose)
            XCTAssertEqual(log.modules.count, 1)
            try log.unregisterModule(module)
            XCTAssertEqual(log.modules.count, 0)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }
    }

    func testUnregisterDestination_WithNonExistingRawValue_ShouldFail() {

        let module = MockLogModule.🚧

        do {
            XCTAssertEqual(log.modules.count, 0)
            try log.unregisterModule(module)
        } catch Log.MultiLoggerError.inexistentModule(let rawValue) {
            XCTAssertEqual(rawValue, module.rawValue)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }
    }

    // log

    func testLog_WithRegisteredModuleAllowingLogLevel_ShouldCallWriteOnAllDestinationsAllowingLogLevel() {
        let writeExpectation = self.expectation(description: "write")
        writeExpectation.expectedFulfillmentCount = 2
        defer { waitForExpectations(timeout: 1) }

        let destination1 = MockLogDestination(id: "1", minLevel: .verbose)
        let destination2 = MockLogDestination(id: "2", minLevel: .verbose)

        do {
            try log.registerDestination(destination1)
            try log.registerDestination(destination2)
            try log.registerModule(.🏗, minLevel: .verbose)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }

        let item = Log.Item.testItem

        let assertItem: (Log.Item, Log.Item) -> Void = { writeItem, item in
            XCTAssertEqual(writeItem.module, MockLogModule.🏗.rawValue)
            XCTAssertEqual(writeItem.level, item.level)
            XCTAssertEqual(writeItem.message, item.message)
            XCTAssertEqual(writeItem.file, item.file)
            XCTAssertEqual(writeItem.function, item.function)
            XCTAssertEqual(writeItem.line, item.line)
        }

        destination1.writeInvokedClosure = { writeItem, _ in
            assertItem(writeItem, item)
            writeExpectation.fulfill()
        }

        destination2.writeInvokedClosure = { writeItem, _ in
            assertItem(writeItem, item)
            writeExpectation.fulfill()
        }

        log.log(module: .🏗,
                level: .verbose,
                message: "message",
                file: "filename.ext",
                line: 1337,
                function: "function")
    }

    func testLog_WithNoModule_ShouldCallWriteOnAllDestinationsAllowingLogLevel() {
        let writeExpectation = self.expectation(description: "write")
        writeExpectation.expectedFulfillmentCount = 2
        defer { waitForExpectations(timeout: 1) }

        let destination1 = MockLogDestination(id: "1", minLevel: .verbose)
        let destination2 = MockLogDestination(id: "2", minLevel: .verbose)

        do {
            try log.registerDestination(destination1)
            try log.registerDestination(destination2)
            try log.registerModule(.🏗, minLevel: .verbose)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }

        let item = Log.Item.testItem

        let assertItem: (Log.Item, Log.Item) -> Void = { writeItem, item in
            XCTAssertNil(writeItem.module)
            XCTAssertEqual(writeItem.level, item.level)
            XCTAssertEqual(writeItem.message, item.message)
            XCTAssertEqual(writeItem.file, item.file)
            XCTAssertEqual(writeItem.function, item.function)
            XCTAssertEqual(writeItem.line, item.line)
        }

        destination1.writeInvokedClosure = { writeItem, _ in
            assertItem(writeItem, item)
            writeExpectation.fulfill()
        }

        destination2.writeInvokedClosure = { writeItem, _ in
            assertItem(writeItem, item)
            writeExpectation.fulfill()
        }

        log.log(level: .verbose,
                message: "message",
                file: "filename.ext",
                line: 1337,
                function: "function")
    }

    func testLog_WithNotRegisteredModule_ShouldNotCallWriteOnAnyDestination() {
        let destination1 = MockLogDestination(id: "1", minLevel: .verbose)
        let destination2 = MockLogDestination(id: "2", minLevel: .verbose)

        do {
            try log.registerDestination(destination1)
            try log.registerDestination(destination2)
            try log.registerModule(.🏗, minLevel: .verbose)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }

        destination1.writeInvokedClosure = { _, _ in XCTFail("unexpected call!") }
        destination2.writeInvokedClosure = { _, _ in XCTFail("unexpected call!") }

        log.log(module: .🚧,
                level: .verbose,
                message: "message",
                file: "filename.ext",
                line: 1337,
                function: "function")
    }

    func testLog_WithRegisteredModuleNotAllowingLogLevel_ShouldNotCallWriteOnDestination() {
        let destination = MockLogDestination(id: "1", minLevel: .verbose)

        do {
            try log.registerDestination(destination)
            try log.registerModule(.🏗, minLevel: .error)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }

        destination.writeInvokedClosure = { _, _ in XCTFail("unexpected call!") }

        log.log(module: .🏗,
                level: .verbose,
                message: "message",
                file: "filename.ext",
                line: 1337,
                function: "function")
    }

    func testLog_WithRegisteredModuleAllowingLogLevelAndDestinationNotAllowingLogLevel_ShouldNotCallWriteOnDestination() {
        let destination = MockLogDestination(id: "1", minLevel: .error)

        do {
            try log.registerDestination(destination)
            try log.registerModule(.🏗, minLevel: .verbose)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }

        destination.writeInvokedClosure = { _, _ in XCTFail("unexpected call!") }

        log.log(module: .🏗,
                level: .verbose,
                message: "message",
                file: "filename.ext",
                line: 1337,
                function: "function")
    }

    func testLog_WithRegisteredModuleAllowingLogLevelAndFailingDestinationAllowingLogLevel_ShouldCallErrorClosure() {
        let writeExpectation = self.expectation(description: "write")
        let errorExpectation = self.expectation(description: "error")
        defer { waitForExpectations(timeout: 1) }

        let destination = MockLogDestination(id: "1", minLevel: .verbose)

        let onError: MultiLogger.LogDestinationErrorClosure = { errorDestination, error in
            defer { errorExpectation.fulfill() }
            XCTAssertEqual(errorDestination.id, destination.id)
            guard case MockError.😱 = error else { return XCTFail("unexpected error \(error)") }
        }

        log = MultiLogger(onError: onError)

        do {
            try log.registerDestination(destination)
            try log.registerModule(.🏗, minLevel: .verbose)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }

        let item = Log.Item.testItem

        destination.writeInvokedClosure = { writeItem, failure in
            XCTAssertEqual(writeItem.module, MockLogModule.🏗.rawValue)
            XCTAssertEqual(writeItem.level, item.level)
            XCTAssertEqual(writeItem.message, item.message)
            XCTAssertEqual(writeItem.file, item.file)
            XCTAssertEqual(writeItem.function, item.function)
            XCTAssertEqual(writeItem.line, item.line)

            failure(MockError.😱)

            writeExpectation.fulfill()
        }

        log.log(module: .🏗,
                level: .verbose,
                message: "message",
                file: "filename.ext",
                line: 1337,
                function: "function")
    }

    // setMetadata

    func testSetMetadata_ShouldCallSetMetadataOnAllDestinations() {
        let metadataExpectation = self.expectation(description: "set metadata")
        metadataExpectation.expectedFulfillmentCount = 2
        defer { waitForExpectations(timeout: 1) }

        let destination1 = MockLogDestination(id: "1")
        let destination2 = MockLogDestination(id: "2")

        do {
            try log.registerDestination(destination1)
            try log.registerDestination(destination2)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }

        let testMetadata: [MockMetadataKey : Any] = [.👤 : "Minder", .📱 : "iPhone 1337", .📊 : Double.pi]

        destination1.setMetadataInvokedClosure = { metadata, _ in
            XCTAssertDumpsEqual(metadata, testMetadata)
            metadataExpectation.fulfill()
        }

        destination2.setMetadataInvokedClosure = { metadata, _ in
            XCTAssertDumpsEqual(metadata, testMetadata)
            metadataExpectation.fulfill()
        }

        log.setMetadata(testMetadata)
    }

    func testSetMetadata_WithFailingSetMetadataOnDestination_ShouldCallErrorClosure() {
        let metadataExpectation = self.expectation(description: "set metadata")
        let errorExpectation = self.expectation(description: "error")
        defer { waitForExpectations(timeout: 1) }

        let destination = MockLogDestination(id: "1")

        let onError: MultiLogger.LogDestinationErrorClosure = { errorDestination, error in
            defer { errorExpectation.fulfill() }
            XCTAssertEqual(errorDestination.id, destination.id)
            guard case MockError.😱 = error else { return XCTFail("unexpected error \(error)") }
        }

        log = MultiLogger(onError: onError)

        do {
            try log.registerDestination(destination)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }

        let testMetadata: [MockMetadataKey : Any] = [.👤 : "Minder", .📱 : "iPhone 1337", .📊 : Double.pi]

        destination.setMetadataInvokedClosure = { metadata, failure in
            XCTAssertDumpsEqual(metadata, testMetadata)
            failure(MockError.😱)
            metadataExpectation.fulfill()
        }

        log.setMetadata(testMetadata)
    }

    // removeMetadata

    func testRemoveMetadata_ShouldCallRemoveMetadataOnAllDestinations() {
        let metadataExpectation = self.expectation(description: "remove metadata")
        metadataExpectation.expectedFulfillmentCount = 2
        defer { waitForExpectations(timeout: 1) }

        let destination1 = MockLogDestination(id: "1")
        let destination2 = MockLogDestination(id: "2")

        do {
            try log.registerDestination(destination1)
            try log.registerDestination(destination2)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }

        let testMetadataKeys: [MockMetadataKey] = [.👤, .📱, .📊]

        destination1.removeMetadataInvokedClosure = { keys, _ in
            XCTAssertDumpsEqual(keys, testMetadataKeys)
            metadataExpectation.fulfill()
        }

        destination2.removeMetadataInvokedClosure = { keys, _ in
            XCTAssertDumpsEqual(keys, testMetadataKeys)
            metadataExpectation.fulfill()
        }

        log.removeMetadata(forKeys: testMetadataKeys)
    }

    func testRemoveMetadata_WithFailingRemoveMetadataOnDestination_ShouldCallErrorClosure() {
        let metadataExpectation = self.expectation(description: "remove metadata")
        let errorExpectation = self.expectation(description: "error")
        defer { waitForExpectations(timeout: 1) }

        let destination = MockLogDestination(id: "1")

        let onError: MultiLogger.LogDestinationErrorClosure = { errorDestination, error in
            defer { errorExpectation.fulfill() }
            XCTAssertEqual(errorDestination.id, destination.id)
            guard case MockError.😱 = error else { return XCTFail("unexpected error \(error)") }
        }

        log = MultiLogger(onError: onError)

        do {
            try log.registerDestination(destination)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }

        let testMetadataKeys: [MockMetadataKey] = [.👤, .📱, .📊]

        destination.removeMetadataInvokedClosure = { keys, failure in
            XCTAssertDumpsEqual(keys, testMetadataKeys)
            failure(MockError.😱)
            metadataExpectation.fulfill()
        }

        log.removeMetadata(forKeys: testMetadataKeys)
    }

    // errorClosure

    func testErrorClosure_WithDefaultValueFailingDestinationOperation_ShouldCallDefaultErrorClosure() {
        let writeExpectation = self.expectation(description: "write")
        defer { waitForExpectations(timeout: 1) }

        let destination = MockLogDestination(id: "1", minLevel: .verbose)

        do {
            try log.registerDestination(destination)
            try log.registerModule(.🏗, minLevel: .verbose)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }

        destination.writeInvokedClosure = { _, failure in
            failure(MockError.😱)
            writeExpectation.fulfill()
        }

        log.log(module: .🏗, level: .verbose, message: "")
    }

}

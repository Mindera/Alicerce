import XCTest
@testable import Alicerce

class MultiLoggerTestCase: XCTestCase {

    enum MockError: Error { case 😱 }
    enum MockLogModule: String, LogModule { case 🏗, 🚧 }
    enum MockMetadataKey { case 👤, 📱, 📊 }

    typealias MockLogDestination = MockMetadataLogDestination<MockLogModule, MockMetadataKey>
    typealias MultiLogger = Log.MultiLogger<MockLogModule, MockMetadataKey>

    // init

    func testInit_WithResultBuilder_ShouldInstantiateCorrectDestinations() {

        let destination1 = MockLogDestination()
        let destination2 = MockLogDestination()
        let destination3 = MockLogDestination()
        let destination4 = MockLogDestination()
        let destinationOpt = MockLogDestination()
        let destinationTrue = MockLogDestination()
        let destinationFalse = MockLogDestination()
        let destinationArray = (1...3).map { _ in MockLogDestination() }
        let destinationAvailable = MockLogDestination()

        let optVar: Bool? = true
        let optNil: Bool? = nil
        let trueVar = true
        let falseVar = false

        let log = MultiLogger {
            destination1
            destination2

            destination3.eraseToAnyMetadataLogDestination()

            [destination4].map { $0.eraseToAnyMetadataLogDestination() }

            if let _ = optVar { destinationOpt }
            if let _ = optNil { destinationOpt }

            if trueVar {
                destinationTrue
            } else {
                destinationFalse
            }

            if falseVar {
                destinationTrue
            } else {
                destinationFalse
            }

            for tracker in destinationArray { tracker }

            if #available(iOS 1.337, *) { destinationAvailable }
        }

        XCTAssertDumpsEqual(
            log.destinations,
            (
                [
                    destination1,
                    destination2,
                    destination3,
                    destination4,
                    destinationOpt,
                    destinationTrue,
                    destinationFalse
                ]
                + destinationArray
                + [destinationAvailable]
            )
            .map { $0.eraseToAnyMetadataLogDestination() }
        )
    }

    // log

    func testLog_WithRegisteredModuleAllowingLogLevel_ShouldCallWriteOnAllDestinationsAllowingLogLevel() {

        let writeExpectation = self.expectation(description: "write")
        writeExpectation.expectedFulfillmentCount = 2
        defer { waitForExpectations(timeout: 1) }

        let destination1 = MockLogDestination(mockMinLevel: .verbose)
        let destination2 = MockLogDestination(mockMinLevel: .verbose)

        let log = MultiLogger(
            destinations: [destination1, destination2].map { $0.eraseToAnyMetadataLogDestination() },
            modules: [.🏗: .verbose]
        )

        let item = Log.Item.dummy()

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

        log.log(
            module: .🏗,
            level: .verbose,
            message: "message",
            file: "filename.ext",
            line: 1337,
            function: "function"
        )
    }

    func testLog_WithNoModule_ShouldCallWriteOnAllDestinationsAllowingLogLevel() {

        let writeExpectation = self.expectation(description: "write")
        writeExpectation.expectedFulfillmentCount = 2
        defer { waitForExpectations(timeout: 1) }

        let destination1 = MockLogDestination(mockMinLevel: .verbose)
        let destination2 = MockLogDestination(mockMinLevel: .verbose)

        let log = MultiLogger(
            destinations: [destination1, destination2].map { $0.eraseToAnyMetadataLogDestination() },
            modules: [.🏗: .verbose]
        )

        let item = Log.Item.dummy()

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

        log.log(
            level: .verbose,
            message: "message",
            file: "filename.ext",
            line: 1337,
            function: "function"
        )
    }

    func testLog_WithNotRegisteredModule_ShouldNotCallWriteOnAnyDestination() {

        let destination1 = MockLogDestination(mockMinLevel: .verbose)
        let destination2 = MockLogDestination(mockMinLevel: .verbose)

        let log = MultiLogger(
            destinations: [destination1, destination2].map { $0.eraseToAnyMetadataLogDestination() },
            modules: [.🏗: .verbose]
        )

        destination1.writeInvokedClosure = { _, _ in XCTFail("unexpected call!") }
        destination2.writeInvokedClosure = { _, _ in XCTFail("unexpected call!") }

        log.log(
            module: .🚧,
            level: .verbose,
            message: "message",
            file: "filename.ext",
            line: 1337,
            function: "function"
        )
    }

    func testLog_WithRegisteredModuleNotAllowingLogLevel_ShouldNotCallWriteOnDestination() {

        let destination = MockLogDestination(mockMinLevel: .verbose)

        let log = MultiLogger(
            destinations: [destination].map { $0.eraseToAnyMetadataLogDestination() },
            modules: [.🏗: .error]
        )

        destination.writeInvokedClosure = { _, _ in XCTFail("unexpected call!") }

        log.log(
            module: .🏗,
            level: .verbose,
            message: "message",
            file: "filename.ext",
            line: 1337,
            function: "function"
        )
    }

    func testLog_WithRegisteredModuleAllowingLogLevelAndDestinationNotAllowingLogLevel_ShouldNotCallWriteOnDestination() {

        let destination = MockLogDestination(mockMinLevel: .error)

        let log = MultiLogger(
            destinations: [destination].map { $0.eraseToAnyMetadataLogDestination() },
            modules: [.🏗: .verbose]
        )

        destination.writeInvokedClosure = { _, _ in XCTFail("unexpected call!") }

        log.log(
            module: .🏗,
            level: .verbose,
            message: "message",
            file: "filename.ext",
            line: 1337,
            function: "function"
        )
    }

    func testLog_WithRegisteredModuleAllowingLogLevelAndFailingDestinationAllowingLogLevel_ShouldCallErrorClosure() {

        let writeExpectation = self.expectation(description: "write")
        let errorExpectation = self.expectation(description: "error")
        defer { waitForExpectations(timeout: 1) }

        let destination = MockLogDestination(mockMinLevel: .verbose)

        let onError: MultiLogger.LogDestinationErrorClosure = { errorDestination, error in
            defer { errorExpectation.fulfill() }
            XCTAssertIdentical((errorDestination as? AnyMetadataLogDestination<MockMetadataKey>)?._wrapped, destination)
            guard case MockError.😱 = error else { return XCTFail("unexpected error \(error)") }
        }

        let log = MultiLogger(
            destinations: [destination].map { $0.eraseToAnyMetadataLogDestination() },
            modules: [.🏗: .verbose],
            onError: onError
        )

        let item = Log.Item.dummy()

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

        log.log(
            module: .🏗,
            level: .verbose,
            message: "message",
            file: "filename.ext",
            line: 1337,
            function: "function"
        )
    }

    // setMetadata

    func testSetMetadata_ShouldCallSetMetadataOnAllDestinations() {

        let metadataExpectation = self.expectation(description: "set metadata")
        metadataExpectation.expectedFulfillmentCount = 2
        defer { waitForExpectations(timeout: 1) }

        let destination1 = MockLogDestination()
        let destination2 = MockLogDestination()

        let log = MultiLogger(destinations: [destination1, destination2].map { $0.eraseToAnyMetadataLogDestination() })

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

        let destination = MockLogDestination()

        let onError: MultiLogger.LogDestinationErrorClosure = { errorDestination, error in
            defer { errorExpectation.fulfill() }
            XCTAssertIdentical((errorDestination as? AnyMetadataLogDestination<MockMetadataKey>)?._wrapped, destination)
            guard case MockError.😱 = error else { return XCTFail("unexpected error \(error)") }
        }

        let log = MultiLogger(
            destinations: [destination].map { $0.eraseToAnyMetadataLogDestination() },
            onError: onError
        )

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

        let destination1 = MockLogDestination()
        let destination2 = MockLogDestination()

        let log = MultiLogger(destinations: [destination1, destination2].map { $0.eraseToAnyMetadataLogDestination() })

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

        let destination = MockLogDestination()

        let onError: MultiLogger.LogDestinationErrorClosure = { errorDestination, error in
            defer { errorExpectation.fulfill() }
            XCTAssertIdentical((errorDestination as? AnyMetadataLogDestination<MockMetadataKey>)?._wrapped, destination)
            guard case MockError.😱 = error else { return XCTFail("unexpected error \(error)") }
        }

        let log = MultiLogger(
            destinations: [destination].map { $0.eraseToAnyMetadataLogDestination() },
            onError: onError
        )

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

        let destination = MockLogDestination(mockMinLevel: .verbose)

        let log = MultiLogger(
            destinations: [destination].map { $0.eraseToAnyMetadataLogDestination() },
            modules: [.🏗: .verbose]
        )

        destination.writeInvokedClosure = { _, failure in
            failure(MockError.😱)
            writeExpectation.fulfill()
        }

        log.log(module: .🏗, level: .verbose, message: "")
    }
}

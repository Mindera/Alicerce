import XCTest
@testable import Alicerce

class MetadataLoggerTestCase: XCTestCase {

    enum MockError: Error { case 💣 }
    enum MockMetadataKey { case 👤, 📱, 📊 }

    typealias MockLogDestination = MockMetadataLogDestination<Log.NoModule, MockMetadataKey>

    func testSetMetadata_WithMetadataLogDestination_ShouldInvokeSetMetadataWithDefaultErrorClosure() {

        let log = MockLogDestination()

        let testMetadata: [MockMetadataKey : Any] = [.👤 : "Minder", .📱 : "iPhone 1337", .📊 : Double.pi]

        log.setMetadataInvokedClosure = { metadata, errorClosure in
            XCTAssertDumpsEqual(metadata, testMetadata)
            errorClosure(MockError.💣)
        }

        log.setMetadata(testMetadata)
    }

    func testRemoveMetadata_WithMetadataLogDestination_ShouldInvokeRemoveMetadataWithDefaultErrorClosure() {

        let log = MockLogDestination()

        let testMetadataKeys: [MockMetadataKey] = [.👤, .📱, .📊]

        log.removeMetadataInvokedClosure = { keys, errorClosure in
            XCTAssertEqual(keys, testMetadataKeys)
            errorClosure(MockError.💣)
        }

        log.removeMetadata(forKeys: testMetadataKeys)
    }

}

import XCTest
@testable import Alicerce

class LogDestinationTestCase: XCTestCase {
    
    func testID_ShouldReturnTypeName() {
        let destination = DummyLogDestination()

        XCTAssertEqual(destination.id, "\(type(of: destination))")
    }
}

final class DummyLogDestination: LogDestination {

    let minLevel: Log.Level = .verbose

    func write(item: Log.Item, onFailure: @escaping (Error) -> Void) {}

    func setMetadata(_ metadata: [AnyHashable : Any], onFailure: @escaping (Error) -> Void) {}

    func removeMetadata(forKeys keys: [AnyHashable], onFailure: @escaping (Error) -> Void) {}
}

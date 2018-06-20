import XCTest
@testable import Alicerce

class JSONLogItemFormatterTests: XCTestCase {

    fileprivate var log: Log!

    override func setUp() {
        super.setUp()

        log = Log()
    }

    override func tearDown() {
        log = nil

        super.tearDown()
    }

    func testLogItemJSONFormatter() {

        // preparation of the test subject

        let destination = Log.StringLogDestination(minLevel: .verbose,
                                                   formatter: Log.JSONLogItemFormatter(),
                                                   logSeparator: ",")

        // execute test

        do {
            try log.register(destination)
        } catch {
            return XCTFail("unexpected error \(error)!")
        }

        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        let jsonString = "[\(destination.output)]"
        let jsonData = jsonString.data(using: .utf8)

        let obj: Any
        do {
            obj = try JSONSerialization.jsonObject(with: jsonData!, options: .allowFragments)
        } catch {
            return XCTFail("failed to serialize json from log output with error \(error)")
        }

        guard let arr = obj as? [JSON.Dictionary] else {
            return XCTFail("🔥: expected a dictionary from JSON serialization but got something different")
        }

        XCTAssertEqual(arr.count, 5)

        let levelsAndMessages: [(Int, String)] = arr.compactMap {
            guard
                let level = $0[Log.JSONLogItemFormatter.LogKey.level] as? Int,
                let message = $0[Log.JSONLogItemFormatter.LogKey.message] as? String
            else {
                XCTFail("unexpected type in log json!")
                return nil
            }

            return (level, message)
        }

        let expectedLevelsAndMessages = [(0, "verbose message"),
                                         (1, "debug message"),
                                         (2, "info message"),
                                         (3, "warning message"),
                                         (4, "error message")]

        XCTAssertEqual(levelsAndMessages.count, expectedLevelsAndMessages.count)

        zip(levelsAndMessages, expectedLevelsAndMessages).forEach { assertDumpsEqual($0, $1) }

    }
}

import Foundation
@testable import Alicerce

final class MockLogLevelFormatter: LogLevelFormatter {

    // mocks

    var mockColorEscape: String = "$cE"
    var mockColorReset: String = "$cR"

    var mockColorString: (Log.Level) -> String = { _ in "🌈" }
    var mockLabelString: (Log.Level) -> String = { _ in "LABEL" }

    // LogItemLevelFormatter

    var colorEscape: String { return mockColorEscape}
    var colorReset: String { return mockColorReset }

    func colorString(for level: Log.Level) -> String {
        return mockColorString(level)
    }

    func labelString(for level: Log.Level) -> String {
        return mockLabelString(level)
    }
}

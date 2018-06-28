import Foundation
@testable import Alicerce

final class MockStringLogItemFormatter: LogItemFormatter {

    var mockFormat: (Log.Item) throws -> String = { _ in "📝" }

    func format(item: Log.Item) throws -> String {
        return try mockFormat(item)
    }
}

final class MockDataLogItemFormatter: LogItemFormatter {

    var mockFormat: (Log.Item) throws -> Data = { _ in Data() }

    func format(item: Log.Item) throws -> Data {
        return try mockFormat(item)
    }
}

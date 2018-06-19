public protocol LogItemLevelFormatter {

    var colorEscape: String { get }
    var colorReset: String { get }

    func colorString(for level: Log.Level) -> String
    func labelString(for level: Log.Level) -> String
}

public extension LogItemLevelFormatter {

    var colorEscape: String {
        return ""
    }

    var colorReset: String {
        return ""
    }

    func colorString(for level: Log.Level) -> String {

        switch level {
        case .verbose: return "📓"
        case .debug: return "📗"
        case .info: return "📘"
        case .warning: return "📒"
        case .error: return "📕"
        }
    }

    func labelString(for level: Log.Level) -> String {
        switch level {
        case .verbose: return "VERBOSE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        }
    }
}

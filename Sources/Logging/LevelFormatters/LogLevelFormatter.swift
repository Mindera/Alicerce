import Foundation

/// A type that formats a log level.
public protocol LogLevelFormatter {

    /// The formatter's color escape sequence (e.g. for bash output). The default is an empty string.
    var colorEscape: String { get }

    /// The formatter's color escape reset sequence (e.g. for bash output). The default is an empty string.
    var colorReset: String { get }

    /// Formats a log level into a _color_ string representation.
    ///
    /// The default values are:
    /// - `.verbose`: `"📓"`
    /// - `.debug`: `"📗"`
    /// - `.info`: `"📘"`
    /// - `.warning`: `"📒"`
    /// - `.error`: `"📕"`
    ///
    /// - Parameter level: the log level to format.
    /// - Returns: A string representing the color of the formatted log level.
    func colorString(for level: Log.Level) -> String

    /// Formats a log item into a _label_ string representation.
    ///
    /// The default values are:
    /// - `.verbose`: `"VERBOSE"`
    /// - `.debug`: `"DEBUG"`
    /// - `.info`: `"INFO"`
    /// - `.warning`: `"WARNING"`
    /// - `.error`: `"ERROR"`
    ///
    /// - Parameter level: The log level to format.
    /// - Returns: A string representing the label of the formatted log level.
    func labelString(for level: Log.Level) -> String
}

public extension LogLevelFormatter {

    var colorEscape: String { return "" }
    var colorReset: String { return "" }

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

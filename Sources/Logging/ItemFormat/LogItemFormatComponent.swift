import Foundation

/// A type that represents a log format chain component that converts log items into an output.
public protocol LogItemFormatComponent {

    /// The formatter's output type.
    associatedtype Output

    /// The formatter's formatting witness.
    var formatting: Log.ItemFormat.Formatting<Output> { get }
}

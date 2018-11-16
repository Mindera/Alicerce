/// A type that formats a log item into an output format.
public protocol LogItemFormatter {

    /// The formatter's output type.
    associatedtype Output

    /// Formats a log item into an instance of the output type.
    ///
    /// - Parameter item: The log item to format.
    /// - Returns: An `Output` instance representing the formatted log item.
    func format(item: Log.Item) throws -> Output
}

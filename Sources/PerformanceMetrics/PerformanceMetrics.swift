import Foundation

/// A type representing the Analytics namespace (case-less enum).
public enum PerformanceMetrics {

    /// A phantom type representing a performance metric's instance tag (used on the `Token`'s).
    public enum Tag {}

    /// A metric identifier.
    public typealias Identifier = String

    /// A metric metadata dictionary.
    public typealias Metadata = [String : Any]
}

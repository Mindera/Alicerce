import Foundation

/// A type representing the key of an analytics event parameter dictionary.
public protocol AnalyticsParameterKey: Hashable, RawRepresentable where RawValue == String {}

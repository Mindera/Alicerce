import Foundation

/// A type representing an application's module (i.e. subsystem).
public protocol LogModule: Hashable, RawRepresentable where RawValue == String {}

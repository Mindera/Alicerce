//
//  Box.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 03/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

/// An arbitrary container which stores a **constant** value of type `T`.
///
/// This main purpose of this object is to encapsulate value types so that they can be used like a reference type
/// (e.g. pass value types around without copying them, "share" value types between closures, etc)
public final class Box<T> {

    /// The encapsulated value.
    public let value: T

    /// Instantiate a new constant value box with the given value.
    ///
    /// - parameter value: the value to encapsulate.
    ///
    /// - returns: a newly instantiated box with the encapsulated value.
    public init(_ value: T) { self.value = value }
}

/// An arbitrary container which stores a **variable** value of type `T`.
///
/// This main purpose of this object is to encapsulate value types so that they can be used like a reference type
/// (e.g. pass value types around without copying them, "share" value types between closures, etc)
public final class VarBox<T> {
    
    /// The encapsulated value.
    public var value: T

    /// Instantiate a new variable value box with the given value.
    ///
    /// - parameter value: the value to encapsulate.
    ///
    /// - returns: a newly instantiated box with the encapsulated value.
    public init(_ value: T) { self.value = value }
}

//  Copied and modified from https://github.com/ReactiveCocoa/ReactiveSwift/blob/master/Sources/Atomic.swift 🙏
//
//  Copyright (c) 2012 - 2018, GitHub, Inc.
//  All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation
import MachO

/// `Lock` exposes `os_unfair_lock` on supported platforms, with pthread mutex as the fallback.
public class Lock {
    @available(iOS 10.0, *)
    final class UnfairLock: Lock {
        private let _lock: os_unfair_lock_t

        override init() {
            _lock = .allocate(capacity: 1)
            _lock.initialize(to: os_unfair_lock())
            super.init()
        }

        override func lock() {
            os_unfair_lock_lock(_lock)
        }

        override func unlock() {
            os_unfair_lock_unlock(_lock)
        }

        override func `try`() -> Bool {
            return os_unfair_lock_trylock(_lock)
        }

        deinit {
            _lock.deinitialize(count: 1)
            _lock.deallocate()
        }
    }

    final class PthreadLock: Lock {
        private let _lock: UnsafeMutablePointer<pthread_mutex_t>

        init(recursive: Bool = false) {
            _lock = .allocate(capacity: 1)
            _lock.initialize(to: pthread_mutex_t())

            let attr = UnsafeMutablePointer<pthread_mutexattr_t>.allocate(capacity: 1)
            attr.initialize(to: pthread_mutexattr_t())
            pthread_mutexattr_init(attr)

            defer {
                pthread_mutexattr_destroy(attr)
                attr.deinitialize(count: 1)
                attr.deallocate()
            }

            // Darwin pthread for 32-bit ARM somehow returns `EAGAIN` when
            // using `trylock` on a `PTHREAD_MUTEX_ERRORCHECK` mutex.
            #if DEBUG && !arch(arm)
            pthread_mutexattr_settype(attr, Int32(recursive ? PTHREAD_MUTEX_RECURSIVE : PTHREAD_MUTEX_ERRORCHECK))
            #else
            pthread_mutexattr_settype(attr, Int32(recursive ? PTHREAD_MUTEX_RECURSIVE : PTHREAD_MUTEX_NORMAL))
            #endif

            let status = pthread_mutex_init(_lock, attr)
            assert(status == 0, "Unexpected pthread mutex error code: \(status)")

            super.init()
        }

        override func lock() {
            let status = pthread_mutex_lock(_lock)
            assert(status == 0, "Unexpected pthread mutex error code: \(status)")
        }

        override func unlock() {
            let status = pthread_mutex_unlock(_lock)
            assert(status == 0, "Unexpected pthread mutex error code: \(status)")
        }

        override func `try`() -> Bool {
            let status = pthread_mutex_trylock(_lock)
            switch status {
            case 0:
                return true
            case EBUSY:
                return false
            default:
                assertionFailure("Unexpected pthread mutex error code: \(status)")
                return false
            }
        }

        deinit {
            let status = pthread_mutex_destroy(_lock)
            assert(status == 0, "Unexpected pthread mutex error code: \(status)")

            _lock.deinitialize(count: 1)
            _lock.deallocate()
        }
    }

    /// Return an instance of a `Lock`, according to API availability (`os_unfair_lock_t` or `pthread_mutex_t` based).
    ///
    /// - returns: a `Lock` instance
    public static func make() -> Lock {
        if #available(*, iOS 10.0) {
            return UnfairLock()
        }

        return PthreadLock()
    }

    private init() {}

    /// Locks the lock
    public func lock() { fatalError("Missing Implementation") }

    /// Unlocks the lock
    public func unlock() { fatalError("Missing Implementation") }

    /// Locks the lock if it is not already locked.
    ///
    /// - Returns: Returns `true` if the lock was succesfully locked and `false` if the lock was already locked.
    public func `try`() -> Bool { fatalError("Missing Implementation") }
}

import Foundation

/// An enum representing the application's mode (Debug, Release).
public enum ApplicationMode: String {

    /// The application is running in Debug mode.
    case debug

    /// The application is running in Release mode.
    case release

    /// The current application's mode.
    public static var current: ApplicationMode {
        #if DEBUG
            return .debug
        #else
            return .release
        #endif
    }
}

import Foundation

/// A type representing the Analytics namespace (case-less enum).
public enum Analytics {

    /// A typealias representing a dictionary of analytics parameters.
    public typealias Parameters<Key: AnalyticsParameterKey> = [Key : Any]

    /// An analytics event representing either a state update or a user action, with an associated value and parameters.
    ///
    /// The goal is to allow using a type safe representation of all possible analytics event types, e.g. using
    /// `enum`'s for `State` and `Action` types.
    ///
    /// Examples of *state* events:
    /// - screen display
    /// - user login/logout
    /// - any global state
    ///
    /// Examples of *action* events:
    /// - button tap
    /// - scroll event
    /// - any user input (e.g. search term)
    public enum Event<State, Action, Key: AnalyticsParameterKey> {
        case state(State, Parameters<Key>?)
        case action(Action, Parameters<Key>?)
    }
}

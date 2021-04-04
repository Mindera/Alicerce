import Foundation

/// A type that tracks analytics events.
public protocol AnalyticsTracker: AnyObject {

    /// A type that represents all the possible types that the tracker's `Event.state` event can have.
    associatedtype State

    /// A type that represents all the possible types that the tracker's `Event.action` event can have.
    associatedtype Action

    /// A type that represents all the possible parameter keys that a tracker's `Event` parameter dictionary can have.
    associatedtype ParameterKey: AnalyticsParameterKey

    /// An analytics event.
    typealias Event = Analytics.Event<State, Action, ParameterKey>

    /// Tracks an analytics event.
    ///
    /// - Parameter event: The event to track.
    func track(_ event: Event)
}

public extension AnalyticsTracker {

    func eraseToAnyAnalyticsTracker() -> Analytics.AnyAnalyticsTracker<State, Action, ParameterKey> { .init(self) }
}

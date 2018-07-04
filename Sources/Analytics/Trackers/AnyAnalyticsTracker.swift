import Foundation

extension Analytics {

    /// A type-erased analytics tracker.
    public final class AnyAnalyticsTracker<State, Action, ParameterKey: AnalyticsParameterKey>: AnalyticsTracker {

        /// The type-erased tracker's wrapped instance id.
        public let id: ID

        /// The type-erased tracker's wrapped instance `track` method, stored as a closure.
        private let _track: (Analytics.Event<State, Action, ParameterKey>) -> Void

        /// Creates a type-erased instance of an analytics tracker that wraps the given instance.
        ///
        /// - Parameters:
        ///   - tracker: The analytics tracker instance to wrap.
        public init<T: AnalyticsTracker>(_ tracker: T)
        where T.State == State, T.Action == Action, T.ParameterKey == ParameterKey {
            id = tracker.id
            _track = tracker.track
        }

        /// Tracks an analytics event via the wrapped tracker.
        ///
        /// - Parameter event: The analytics event.
        public func track(_ event: Analytics.Event<State, Action, ParameterKey>) {
            _track(event)
        }
    }
}

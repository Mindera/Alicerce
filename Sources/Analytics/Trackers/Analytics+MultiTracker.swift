import Foundation

public extension Analytics {

    /// An error produced by `MultiTracker` instances.
    public enum MultiTrackerError: Swift.Error {

        /// A tracker with the same id already registered.
        case duplicateTracker(AnalyticsTracker.ID)

        /// A tracker with the given id isn't registered.
        case inexistentTracker(AnalyticsTracker.ID)
    }

    /// An analytics tracker that forwards analytics events to multiple trackers, while not doing any tracking on its
    /// own.
    public final class MultiTracker<State, Action, ParameterKey: AnalyticsParameterKey>: AnalyticsTracker {

        /// The registered sub trackers (read only).
        public var trackers: [AnyAnalyticsTracker<State, Action, ParameterKey>] { return _trackers.value }

        /// The registered sub trackers.
        private let _trackers: Atomic<[AnyAnalyticsTracker<State, Action, ParameterKey>]>

        /// Creates an analytics multi tracker instance.
        public init() {
            self._trackers = Atomic<[AnyAnalyticsTracker<State, Action, ParameterKey>]>([])
        }

        // MARK: - Sub-Tracker Management

        /// Registers a sub tracker, and starts sending any new analytics events to it. This method is thread safe.
        ///
        /// - Parameter tracker: The analytics tracker to register.
        /// - Throws: An `Analytics.MultiTrackerError.duplicateTracker` error if a tracker with the same `id` is
        /// already registered.
        public func register<T: AnalyticsTracker>(_ tracker: T) throws
        where T.State == State, T.Action == Action, T.ParameterKey == ParameterKey {
            precondition(tracker.id != id, "🙅‍♂️: Can't register a tracker with the same `id` as `self`!")

            try _trackers.modify {
                guard $0.contains(where: { $0.id == tracker.id }) == false else {
                    throw MultiTrackerError.duplicateTracker(tracker.id)
                }
                $0.append(AnyAnalyticsTracker(tracker))
            }
        }

        /// Unregisters a sub tracker, preventing any new analytics events from being sent to it. This method is thread
        /// safe.
        ///
        /// - Parameter tracker: The analytics tracker to unregister.
        /// - Throws: An `Analytics.MultiTrackerError.inexistentTracker` error if a tracker with the same `id` isn't
        /// registered.
        public func unregister<T: AnalyticsTracker>(_ tracker: T) throws
        where T.State == State, T.Action == Action, T.ParameterKey == ParameterKey {
            try _trackers.modify {
                guard $0.contains(where: { $0.id == tracker.id }) else {
                    throw MultiTrackerError.inexistentTracker(tracker.id)
                }
                $0 = $0.filter { $0.id != tracker.id }
            }
        }

        // MARK: - Tracking

        /// Tracks an analytics event, by propagating it to all the registered sub trackers.
        ///
        /// - Parameter event: The event to track.
        public func track(_ event: Analytics.Event<State, Action, ParameterKey>) {
            let currentTrackers = _trackers.value

            guard currentTrackers.isEmpty == false else { return }

            currentTrackers.forEach { $0.track(event) }
        }
    }
}

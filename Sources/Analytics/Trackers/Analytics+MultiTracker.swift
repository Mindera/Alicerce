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
    /// own. Additionally, it contains a global parameter dictionary that is merged with each analytics event's own
    /// parameter dictionary using a specific merge strategy.
    public final class MultiTracker<Screen, Action, ParameterKey: AnalyticsParameterKey>: AnalyticsTracker {

        /// The registered sub trackers (read only).
        public var subTrackers: [AnyAnalyticsTracker<Screen, Action, ParameterKey>] { return _subTrackers.value }

        /// The registered sub trackers.
        private let _subTrackers: Atomic<[AnyAnalyticsTracker<Screen, Action, ParameterKey>]>

        /// Creates an instance with some default global extra parameters, which are merged with all analytics events'
        /// own parameters.
        ///
        /// - Parameters:
        ///   - globalParameters: The initial global parameters to use. The default is `nil`.
        ///   - parameterMergeStrategy: The strategy to use when merging events' parameters with any current global
        /// ones.
        /// The default is `eventOverGlobal`.
        public init() {
            self._subTrackers = Atomic<[AnyAnalyticsTracker<Screen, Action, ParameterKey>]>([])
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

            try _subTrackers.modify {
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
            try _subTrackers.modify {
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
        public func track(_ event: Analytics.Event<Screen, Action, ParameterKey>) {
            let currentSubTrackers = _subTrackers.value

            guard currentSubTrackers.isEmpty == false else { return }

            currentSubTrackers.forEach { $0.track(event) }
        }
    }
}


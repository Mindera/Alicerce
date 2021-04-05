import Foundation

#if canImport(AlicerceCore)
import AlicerceCore
#endif

public extension Analytics {

    /// An analytics tracker that forwards analytics events to multiple trackers, while not doing any tracking on its
    /// own.
    final class MultiTracker<State, Action, ParameterKey: AnalyticsParameterKey>: AnalyticsTracker {

        /// The registered sub trackers.
        public let trackers: [AnyAnalyticsTracker<State, Action, ParameterKey>]

        /// Creates an analytics multi tracker instance.
        /// - Parameter trackers: The analytics trackers to register.
        public init(trackers: [AnyAnalyticsTracker<State, Action, ParameterKey>]) {

            assert(!trackers.isEmpty, "🙅‍♂️ Trackers shouldn't be empty, since it renders this tracker useless!")

            self.trackers = trackers
        }

        // MARK: - Tracking

        /// Tracks an analytics event, by propagating it to all the registered sub trackers.
        ///
        /// - Parameter event: The event to track.
        public func track(_ event: Analytics.Event<State, Action, ParameterKey>) {

            trackers.forEach { $0.track(event) }
        }
    }
}

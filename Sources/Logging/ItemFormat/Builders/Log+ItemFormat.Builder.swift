extension Log.ItemFormat {

    /// A result builder to build string log formatting witnesses.
    @resultBuilder
    public enum Builder {

        public typealias Formatting<Output> = Log.ItemFormat.Formatting<Output>

        @inlinable
        public static func buildExpression<F: LogItemFormatComponent>(_ formatter: F) -> Formatting<F.Output> {

            formatter.formatting
        }

        @inlinable
        public static func buildExpression<O: RangeReplaceableCollection>(_ kp: KeyPath<Log.Item, O>) -> Formatting<O> {

            .keyPath(kp)
        }

        @inlinable
        public static func buildExpression<O: RangeReplaceableCollection>(_ value: O) -> Formatting<O> {

            .value(value)
        }

        @inlinable
        public static func buildExpression<O>(_ formatting: Formatting<O>) -> Formatting<O> { formatting }

        @inlinable
        public static func buildBlock<O>(_ formattings: Formatting<O>...) -> Formatting<O> {

            formattings.reduce(into: .empty, +=)
        }

        @inlinable
        public static func buildOptional<O>(_ formatting: Formatting<O>?) -> Formatting<O> { formatting ?? .empty }

        @inlinable
        public static func buildEither<O>(first formatting: Formatting<O>) -> Formatting<O> { formatting }

        @inlinable
        public static func buildEither<O>(second formatting: Formatting<O>) -> Formatting<O> { formatting }

        @inlinable
        public static func buildArray<O>(_ formattings: [Formatting<O>]) -> Formatting<O> {

            formattings.reduce(into: .empty, +=)
        }

        @inlinable
        public static func buildLimitedAvailability<O>(_ formatting: Formatting<O>) -> Formatting<O> { formatting }
    }
}

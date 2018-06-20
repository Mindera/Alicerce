public extension Log {

    public struct Item {
        public let level: Level
        public let message: String
        public let file: String
        public let thread: String
        public let function: String
        public let line: UInt
    }
}

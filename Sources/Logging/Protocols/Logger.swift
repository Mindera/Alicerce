public protocol Logger {

    func verbose(_ message: @autoclosure () -> String,
                 file: StaticString,
                 function: StaticString,
                 line: UInt)

    func debug(_ message: @autoclosure () -> String,
               file: StaticString,
               function: StaticString,
               line: UInt)

    func info(_ message: @autoclosure () -> String,
              file: StaticString,
              function: StaticString,
              line: UInt)

    func warning(_ message: @autoclosure () -> String,
                 file: StaticString,
                 function: StaticString,
                 line: UInt)

    func error(_ message: @autoclosure () -> String,
               file: StaticString,
               function: StaticString,
               line: UInt)
}

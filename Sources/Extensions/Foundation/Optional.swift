import Foundation

// Credits to John Sundell
// https://github.com/JohnSundell/Require/

public extension Optional {

    /// Requires the receiving optional to contain a non-nil value.
    ///
    /// This method will either return the value that this optional contains, or trigger a `preconditionFailure` with
    /// an error message containing debug information.
    ///
    /// - Parameters:
    ///   - hintExpression: An optional hint that will get included in any error message generated in case nil is found.
    ///   - file: The file from where this method is invoked.
    ///   - line: The line from where this method is invoked.
    /// - Returns: The value wrapped in the optional.
    func require(hint hintExpression: @autoclosure () -> String? = nil,
                 file: StaticString = #file,
                 line: UInt = #line) -> Wrapped {
        guard let unwrapped = self else {
            var message = "Required value was nil in \(file):\(line)"

            if let hint = hintExpression() {
                message.append(". Debugging hint: \(hint)")
            }

            preconditionFailure(message)
        }

        return unwrapped
    }
}

import Dispatch

extension DispatchQueue {

    // Credits to Brent Royal-Gordon https://lists.swift.org/pipermail/swift-users/Week-of-Mon-20160613/002280.html 🙏

    /// Returns the label of the current queue, as specified when the queue was created.
    public class var currentLabel: String {
        return String(validatingUTF8: __dispatch_queue_get_label(nil)) ?? ""
    }
}

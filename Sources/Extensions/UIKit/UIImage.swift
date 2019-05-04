import UIKit

public extension UIImage {

    var original: UIImage { return withRenderingMode(.alwaysOriginal) }
    var template: UIImage { return withRenderingMode(.alwaysTemplate) }

    convenience init?(base64Encoded encodedString: String) {
        guard let data = Data(base64Encoded: encodedString) else { return nil }
        self.init(data: data)
    }
}

import UIKit
import XCTest

final class TestDummy {}

func dataFromFile(withName name: String, type: String, bundleClass: AnyClass = TestDummy.self) -> Data {
    let filePath = Bundle(for: bundleClass).path(forResource: name, ofType: type)

    guard
        let path = filePath,
        let data = try? Data(contentsOf: URL(fileURLWithPath: path))
    else {
        fatalError("🔥 File not found or invalid data!")
    }

    return data
}

func stringFromFile(withName name: String, type: String, bundleClass: AnyClass = TestDummy.self) -> String {
    let filePath = Bundle(for: bundleClass).path(forResource: name, ofType: type)

    guard
        let path = filePath,
        let string = try? String(contentsOf: URL(fileURLWithPath: path))
    else {
        fatalError("🔥 File not found or invalid data!")
    }

    return string
}

func jsonFromFile(withName name: String,
                  options: JSONSerialization.ReadingOptions = .mutableContainers,
                  bundleClass: AnyClass = TestDummy.self) -> Any {
    let jsonData = dataFromFile(withName: name, type: "json", bundleClass: bundleClass)
    return try! JSONSerialization.jsonObject(with: jsonData, options: options)
}

func imageFromFile(withName name: String, type: String, bundleClass: AnyClass = TestDummy.self) -> UIImage {
    let imageData = dataFromFile(withName: name, type: type, bundleClass: bundleClass)
    return UIImage(data: imageData)!
}

func dataFromImage(_ image: UIImage) -> Data {
    guard let data = image.pngData() else {
        assertionFailure("💥 Could not convert image into data 😱")

        return Data()
    }

    return data
}

extension UIView {

    static func instantiateFromNib<T: UIView>(withOwner owner: Any?,
                                              nibName: String = "Views",
                                              bundle: Bundle = Bundle(for: T.self)) -> T? {
        let nib = UINib(nibName: nibName, bundle: bundle)

        return nib.instantiate(withOwner: owner, options: nil).compactMap { $0 as? T }.first
    }
}

public func XCTAssertDumpsEqual<T>(_ lhs: @autoclosure () -> T,
                                   _ rhs: @autoclosure () -> T,
                                   message: @autoclosure () -> String = "Expected dumps to be equal.",
                                   file: StaticString = #file,
                                   line: UInt = #line) {
    XCTAssertEqual(String(dumping: lhs()), String(dumping: rhs()), message(), file: file, line: line)
}

extension String {

    func url(file: StaticString = #file, line: UInt = #line) -> URL {

        guard let url = URL(string: self) else {
            XCTFail("🔥 failed to create URL from '\(self)!'", file: file, line: line)
            return URL(string: "/")!
        }

        return url
    }
}

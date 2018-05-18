//
//  Utils.swift
//  Alicerce
//
//  Created by Luís Portela on 17/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

class TestDummy {}

func dataFromFile(withName name: String, type: String, bundleClass: AnyClass = TestDummy.self) -> Data {
    let filePath = Bundle(for: bundleClass).path(forResource: name, ofType: type)

    guard
        let path = filePath,
        let data = try? Data(contentsOf: URL(fileURLWithPath: path))
    else {
        fatalError("🔥: file not found or invalid data!")
    }

    return data
}

func stringFromFile(withName name: String, type: String, bundleClass: AnyClass = TestDummy.self) -> String {
    let filePath = Bundle(for: bundleClass).path(forResource: name, ofType: type)

    guard
        let path = filePath,
        let string = try? String(contentsOf: URL(fileURLWithPath: path))
    else {
        fatalError("🔥: file not found or invalid data!")
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
    guard let data = UIImagePNGRepresentation(image) else {
        assertionFailure("💥 could not convert image into data 😱")

        return Data()
    }

    return data
}

extension UIView {

    static func instantiateFromNib<T: UIView>(withOwner owner: Any?, nibName: String = "Views") -> T? {
        let nib = UINib(nibName: nibName, bundle: Bundle(for: T.self))

        return nib.instantiate(withOwner: owner, options: nil).compactMap { $0 as? T }.first
    }
}

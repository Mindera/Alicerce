//
//  Utils.swift
//  Alicerce
//
//  Created by Luís Portela on 17/04/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import UIKit

func dataFromFile(withBundleClass bundleClass: AnyClass, name: String, type: String) -> Data {
    let filePath = Bundle(for: bundleClass).path(forResource: name, ofType: type)

    guard
        let path = filePath,
        let data = try? Data(contentsOf: URL(fileURLWithPath: path))
    else {
        fatalError("🔥: file not found or invalid data!")
    }

    return data
}

func jsonFromFile(withBundleClass bundleClass: AnyClass, name: String, options: JSONSerialization.ReadingOptions = .mutableContainers) -> Any {
    let jsonData = dataFromFile(withBundleClass: bundleClass, name: name, type: "json")
    return try! JSONSerialization.jsonObject(with: jsonData, options: options)
}

func imageFromFile(withBundleClass bundleClass: AnyClass, name: String, type: String) -> UIImage {
    let imageData = dataFromFile(withBundleClass: bundleClass, name: name, type: type)
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

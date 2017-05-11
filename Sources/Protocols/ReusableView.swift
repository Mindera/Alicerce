//
//  ReusableView.swift
//  Alicerce
//
//  Created by Luís Afonso on 16/12/2016.
//  Copyright © 2016 Mindera. All rights reserved.
//

import UIKit

public protocol ReusableView: View {
    static var reuseIdentifier: String { get }
}

public extension ReusableView where Self: UIView {
    static var reuseIdentifier: String { return "\(self)" }
}

public extension ReusableView where Self: UITableViewCell {
    init() {
        self.init(style: .default, reuseIdentifier: Self.reuseIdentifier)

        setupLayout()
    }
}

public extension ReusableView where Self: UITableViewHeaderFooterView {
    init() {
        self.init(reuseIdentifier: Self.reuseIdentifier)

        setupLayout()
    }
}

// MARK: - UICollectionView Reusable properties

public extension UICollectionView {

    func dequeueCell<T: UICollectionViewCell>(`for` indexPath: IndexPath) -> T
    where T: ReusableView {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            assertionFailure("🔥 Did you forget to register cell with identifier `\(T.reuseIdentifier)` for type: `\(T.self)`")
            return T()
        }

        return cell
    }

    func register<T: UICollectionViewCell>(_ cellType: T.Type)
    where T: ReusableView {
        register(cellType, forCellWithReuseIdentifier: cellType.reuseIdentifier)
    }

    func register<T: UICollectionReusableView>(_ viewType: T.Type, forSupplementaryViewOfKind kind: String)
    where T: ReusableView {
        register(viewType, forSupplementaryViewOfKind: kind, withReuseIdentifier: viewType.reuseIdentifier)
    }

    func dequeueSupplementaryView<T: UICollectionReusableView>(forElementKind elementKind: String,
                                                        at indexPath: IndexPath) -> T
    where T: ReusableView {

        guard let supplementaryView = dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                            withReuseIdentifier: T.reuseIdentifier,
                                                                            for: indexPath) as? T else {
            assertionFailure("🔥 SupplementaryView with identifier `\(T.reuseIdentifier)` not registered for type: `\(T.self)`!")
            return T()
        }

        return supplementaryView
    }
}

// MARK: - UITableView Reusable properties

public extension UITableView {

    func dequeueCell<T: UITableViewCell>(`for` indexPath: IndexPath) -> T
    where T: ReusableView {
        guard let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            assertionFailure("🔥 Did you forget to register cell with identifier `\(T.reuseIdentifier)` for type: `\(T.self)`")
            return T()
        }

        return cell
    }

    func dequeueHeaderFooterView<T: UITableViewCell>() -> T
    where T: ReusableView {
        guard let view = dequeueReusableHeaderFooterView(withIdentifier: T.reuseIdentifier) as? T else {
            assertionFailure("🔥 Did you forget to register view with identifier `\(T.reuseIdentifier)` for type: `\(T.self)`")
            return T()
        }

        return view
    }

    func register<T: UITableViewCell>(_ cellType: T.Type)
    where T: ReusableView {
        register(cellType, forCellReuseIdentifier: cellType.reuseIdentifier)
    }

    func registerHeaderFooterView<T: UITableViewCell>(_ viewType: T.Type)
    where T: ReusableView {
        register(viewType, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
    }
}

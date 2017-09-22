import UIKit

public protocol ReusableView {
    static var reuseIdentifier: String { get }
}

public extension ReusableView where Self: UIView {
    static var reuseIdentifier: String { return "\(self)" }
}

extension UICollectionReusableView: ReusableView {}

extension UITableViewCell: ReusableView {}
extension UITableViewHeaderFooterView: ReusableView {}

// MARK: - UICollectionView Reusable properties

public extension UICollectionView {

    func register<T: UICollectionViewCell>(_ cellType: T.Type)
    where T: ReusableView {
        register(cellType, forCellWithReuseIdentifier: cellType.reuseIdentifier)
    }

    func register<T: UICollectionViewCell>(_ cellType: T.Type)
    where T: ReusableView, T: NibView {
        register(cellType.nib, forCellWithReuseIdentifier: cellType.reuseIdentifier)
    }

    func register<T: UICollectionReusableView>(_ viewType: T.Type, forSupplementaryViewOfKind kind: String)
    where T: ReusableView {
        register(viewType, forSupplementaryViewOfKind: kind, withReuseIdentifier: viewType.reuseIdentifier)
    }

    func register<T: UICollectionReusableView>(_ viewType: T.Type, forSupplementaryViewOfKind kind: String)
    where T: ReusableView, T: NibView {
        register(viewType.nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: viewType.reuseIdentifier)
    }

    func dequeueCell<T: UICollectionViewCell>(`for` indexPath: IndexPath) -> T
    where T: ReusableView {
        let anyCell = dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath)

        guard let cell = anyCell as? T else {
            fatalError("🔥: Dequeued Cell with identifier `\(T.reuseIdentifier)` for \(indexPath) is not of " +
                       "type `\(T.self)`! Found: `\(type(of: anyCell))`. Forgot to register?")
        }

        return cell
    }

    func dequeueSupplementaryView<T: UICollectionReusableView>(forElementKind elementKind: String,
                                  at indexPath: IndexPath) -> T
    where T: ReusableView {
        let anySupplementaryView = dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                    withReuseIdentifier: T.reuseIdentifier,
                                                                    for: indexPath)

        guard let supplementaryView = anySupplementaryView as? T else {
            fatalError("🔥: Dequeued SupplementaryView with element kind `\(elementKind)`, " +
                       "identifier `\(T.reuseIdentifier)` for \(indexPath) is not of type `\(T.self)`! " +
                       "Found: `\(type(of: anySupplementaryView))`. Forgot to register?")
        }

        return supplementaryView
    }
    
    func cell<T: UICollectionViewCell>(`for` indexPath: IndexPath) -> T
    where T: ReusableView {
        guard let anyCell = cellForItem(at: indexPath) else {
            fatalError("🔥: No Cell returned for \(indexPath)! Looking for `dequeueCell`?")
        }

        guard let cell = anyCell as? T else {
            fatalError("🔥: Cell at \(indexPath) is not of type: `\(T.self)`! Found: `\(type(of: anyCell))`")
        }

        return cell
    }

    @available(iOS 9, *)
    func supplementaryView<T: UICollectionReusableView>(forElementKind elementKind: String,
                                                        at indexPath: IndexPath) -> T
    where T: ReusableView {
        guard let anySupplementaryView = supplementaryView(forElementKind: elementKind, at: indexPath) else {
            fatalError("🔥: No supplementary view returned with element kind `\(elementKind)` for \(indexPath)! " +
                       "Looking for `dequeueSupplementaryView`?")
        }

        guard let supplementaryView = anySupplementaryView as? T else {
            fatalError("🔥: SupplementaryView with element kind `\(elementKind)` is not of type: `\(T.self)`! " +
                       "Found `\(type(of: anySupplementaryView))`")
        }

        return supplementaryView
    }
}

// MARK: - UITableView Reusable properties

public extension UITableView {

    func register<T: UITableViewCell>(_ cellType: T.Type)
    where T: ReusableView {
        register(cellType, forCellReuseIdentifier: cellType.reuseIdentifier)
    }

    func register<T: UITableViewCell>(_ cellType: T.Type)
    where T: ReusableView, T: NibView {
        register(cellType.nib, forCellReuseIdentifier: cellType.reuseIdentifier)
    }

    func registerHeaderFooterView<T: UITableViewCell>(_ viewType: T.Type)
    where T: ReusableView {
        register(viewType, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
    }

    func registerHeaderFooterView<T: UITableViewCell>(_ viewType: T.Type)
    where T: ReusableView, T: NibView {
        register(viewType.nib, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
    }

    func dequeueCell<T: UITableViewCell>(`for` indexPath: IndexPath) -> T
    where T: ReusableView {
        let anyCell = dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath)

        guard let cell = anyCell as? T else {
            fatalError("🔥: Dequeued Cell with identifier `\(T.reuseIdentifier)` for \(indexPath) is not of " +
                       "type `\(T.self)`! Found: `\(type(of: anyCell))`. Forgot to register?")
        }

        return cell
    }

    func dequeueHeaderFooterView<T: UITableViewHeaderFooterView>() -> T
    where T: ReusableView {
        let anyHeaderFooterView = dequeueReusableHeaderFooterView(withIdentifier: T.reuseIdentifier)

        guard let view = anyHeaderFooterView as? T else {
            fatalError("🔥: Dequeued HeaderFooterView with identifier `\(T.reuseIdentifier)` is not of " +
                       "type `\(T.self)`! Found: `\(type(of: anyHeaderFooterView))`. Forgot to register?")
        }

        return view
    }
    
    func cell<T: UITableViewCell>(`for` indexPath: IndexPath) -> T
    where T: ReusableView {
        guard let anyCell = cellForRow(at: indexPath) else {
            fatalError("🔥: No Cell returned for \(indexPath)! Looking for `dequeueCell`?")
        }

        guard let cell = anyCell as? T else {
            fatalError("🔥: Cell at \(indexPath) is not of type: `\(T.self)`! Found: `\(type(of: anyCell))`. " +
                       "Forgot to register?")
        }

        return cell
    }
    
    func headerView<T: UITableViewHeaderFooterView>(forSection section: Int) -> T
    where T: ReusableView {
        guard let anyHeaderView = headerView(forSection: section) else {
            fatalError("🔥: No HeaderView returned for section: \(section)! Looking for `dequeueHeaderFooterView`?")
        }

        guard let view = anyHeaderView as? T else {
            fatalError("🔥: HeaderView for section: \(section) is not of type: `\(T.self)`! " +
                       "Found `\(type(of: anyHeaderView))`. Forgot to register?")
        }

        return view
    }
    
    func footerView<T: UITableViewHeaderFooterView>(forSection section: Int) -> T
    where T: ReusableView {
        guard let anyFooterView = footerView(forSection: section) else {
            fatalError("🔥: No FooterView returned for section: \(section)! Looking for `dequeueHeaderFooterView`?")
        }

        guard let view = anyFooterView as? T else {
            fatalError("🔥: FooterView for section: \(section) is not of type: `\(T.self)`! " +
                "Found `\(type(of: anyFooterView))`. Forgot to register?")
        }

        return view
    }
}

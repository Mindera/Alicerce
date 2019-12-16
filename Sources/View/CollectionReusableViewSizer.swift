import UIKit

final class CollectionReusableViewSizer<View: UICollectionReusableView & ReusableViewModelView> {

    typealias ViewModel = View.ViewModel

    enum Dimension: Hashable {

        case compressed
        case expanded
        case fixed(CGFloat)
        case custom(CGFloat, UILayoutPriority)

        var size: CGFloat {
            switch self {
            case .compressed:
                return 0
            case .expanded:
                return .greatestFiniteMagnitude
            case .fixed(let size), .custom(let size, _):
                return size
            }
        }

        var priority: UILayoutPriority {
            switch self {
            case .compressed, .expanded:
                return .fittingSizeLevel
            case .fixed:
                return .required
            case .custom(_, let priority):
                return priority
            }
        }
    }

    private lazy var view = View()

    func sizeFor(
        viewModel: ViewModel,
        width: Dimension = .compressed,
        height: Dimension = .compressed,
        attributes: UICollectionViewLayoutAttributes? = nil
    ) -> CGSize {

        assert(view.viewModel == nil, "🧟‍♂️ Zombie view model detected! Kill it with fire!")

        view.viewModel = viewModel // the sizer populates the dummy view with the view model

        attributes.then(f: { view.apply($0) })

        let layoutView: UIView
        switch view {
        case let cell as UICollectionViewCell:
            layoutView = cell.contentView // because UIKit reasons
        default:
            layoutView = view
        }

        let size = layoutView.systemLayoutSizeFitting(
            CGSize(width: width.size, height: height.size),
            withHorizontalFittingPriority: width.priority,
            verticalFittingPriority: height.priority
        )

        view.prepareForReuse() // cleans up the dummy view and sets its viewModel to nil

        return size
    }
}

struct ConstantSizerCacheKey: Hashable {}

protocol SizerViewModelView: ReusableViewModelView {

    associatedtype SizerCacheKey: Hashable = ConstantSizerCacheKey

    static func sizerCacheKeyFor(viewModel: ViewModel) -> SizerCacheKey
}

extension SizerViewModelView where SizerCacheKey == ConstantSizerCacheKey {

    static func sizerCacheKeyFor(viewModel: ViewModel) -> SizerCacheKey { SizerCacheKey() }
}

final class CollectionReusableViewSizerCache<View: UICollectionReusableView & SizerViewModelView> {

    typealias Sizer = CollectionReusableViewSizer<View>

    private struct Key: Hashable {
        let key: View.SizerCacheKey
        let width: Sizer.Dimension
        let height: Sizer.Dimension
    }

    private var sizer = Sizer()
    private var cache = [Key: CGSize]()

    func sizeFor(
        viewModel: Sizer.ViewModel,
        width: Sizer.Dimension = .compressed,
        height: Sizer.Dimension = .compressed,
        attributes: UICollectionViewLayoutAttributes? = nil
    ) -> CGSize {

        let key = Key(key: View.sizerCacheKeyFor(viewModel: viewModel), width: width, height: height)
        if let cachedSize = cache[key] { return cachedSize }
        let size = sizer.sizeFor(viewModel: viewModel, width: width, height: height, attributes: attributes)
        cache[key] = size
        return size
    }
}

final class CollectionReusableViewSizerCacheGroup {

    private var sizers = [String: AnyObject]()

    func sizeFor<View: UICollectionReusableView & SizerViewModelView>(
        _ type: View.Type,
        viewModel: CollectionReusableViewSizer<View>.ViewModel,
        width: CollectionReusableViewSizer<View>.Dimension = .compressed,
        height: CollectionReusableViewSizer<View>.Dimension = .compressed,
        attributes: UICollectionViewLayoutAttributes? = nil
    ) -> CGSize {

        typealias Sizer = CollectionReusableViewSizerCache<View>

        let key = NSStringFromClass(View.self)

        if let sizer = sizers[key] as? Sizer {
            return sizer.sizeFor(viewModel: viewModel, width: width, height: height, attributes: attributes)
        }

        let sizer = Sizer()
        sizers[key] = sizer
        return sizer.sizeFor(viewModel: viewModel, width: width, height: height, attributes: attributes)
    }
}

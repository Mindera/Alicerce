import UIKit

open class ViewModelCollectionReusableView<ViewModel>: CollectionReusableView, ReusableViewModelView {

    open var viewModel: ViewModel? {
        didSet {
            setUpBindings()
        }
    }

    open func setUpBindings() {}

    open override func prepareForReuse() {

        viewModel = nil

        super.prepareForReuse()
    }
}

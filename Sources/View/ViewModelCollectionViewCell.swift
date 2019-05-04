import UIKit

open class ViewModelCollectionViewCell<ViewModel>: CollectionViewCell, ReusableViewModelView {

    open var viewModel: ViewModel? {
        didSet {
            setUpBindings()
        }
    }

    open func setUpBindings() {}
}

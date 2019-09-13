import UIKit

open class ViewModelTableViewCell<ViewModel>: TableViewCell, ReusableViewModelView {

    open var viewModel: ViewModel? {
        didSet {
            setUpBindings()
        }
    }

    open func setUpBindings() {}

    open override func prepareForReuse() {

        super.prepareForReuse()

        viewModel = nil
    }
}

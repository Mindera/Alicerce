import UIKit

open class ViewModelTableViewHeaderFooterView<ViewModel>: TableViewHeaderFooterView, ReusableViewModelView {

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

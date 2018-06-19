import UIKit

open class ViewModelTableViewCell<ViewModel>: TableViewCell, ReusableViewModelView {

    open var viewModel: ViewModel? {
        didSet {
            setUpBindings()
        }
    }

    open func setUpBindings() {}
}

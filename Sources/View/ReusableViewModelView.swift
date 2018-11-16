import Foundation

public protocol ReusableViewModelView: ReusableView, View {
    associatedtype ViewModel

    var viewModel: ViewModel? { get set }

    func setUpBindings()
}

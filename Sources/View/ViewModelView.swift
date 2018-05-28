import Foundation

public protocol ViewModelView: View {
    associatedtype ViewModel

    var viewModel: ViewModel { get }

    init(viewModel: ViewModel)

    func setUpBindings()
}

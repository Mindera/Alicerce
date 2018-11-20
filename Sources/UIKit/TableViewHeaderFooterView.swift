import UIKit

open class TableViewHeaderFooterView: UITableViewHeaderFooterView, View {

    public override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        setUpSubviews()
        setUpConstraints()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setUpSubviews()
        setUpConstraints()
    }

    open func setUpSubviews() {}

    open func setUpConstraints() {}
}

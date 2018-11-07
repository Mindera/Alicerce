import UIKit

open class TableViewCell: UITableViewCell, View {

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

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

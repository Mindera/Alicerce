import UIKit

open class CollectionViewCell: UICollectionViewCell, View {

    public override init(frame: CGRect) {
        super.init(frame: frame)

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
